using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Dashboard : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadDashboard();
            }
        }

        private void LoadDashboard()
        {
            DateTime today = DateTime.Today;
            DateTime weekStart = today.AddDays(-6);
            DashboardDateRange.Text = weekStart.ToString("MMM d", CultureInfo.CurrentCulture) + "–" + today.ToString("MMM d, yyyy", CultureInfo.CurrentCulture);

            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            {
                connection.Open();
                using (SqlCommand userCommand = new SqlCommand("SELECT DisplayName FROM AppUsers WHERE Username = @Username AND IsActive = 1", connection))
                {
                    userCommand.Parameters.AddWithValue("@Username", Context.User.Identity.Name);
                    object name = userCommand.ExecuteScalar();
                    if (name != null && name != DBNull.Value)
                    {
                        UserDisplayName.Text = Server.HtmlEncode(Convert.ToString(name, CultureInfo.CurrentCulture));
                    }
                }

                const string metricsSql = @"SELECT ISNULL(SUM(NetAmount), 0), COUNT(TransactionID)
                                            FROM SalesTransactions WHERE TransactionDate >= @Today;
                                            SELECT ISNULL(SUM(i.QuantitySold), 0)
                                            FROM SalesTransactionItems i
                                            INNER JOIN SalesTransactions t ON t.TransactionID = i.TransactionID
                                            WHERE t.TransactionDate >= @Today;";
                using (SqlCommand metricsCommand = new SqlCommand(metricsSql, connection))
                {
                    metricsCommand.Parameters.Add("@Today", SqlDbType.DateTime2).Value = today;
                    using (SqlDataReader reader = metricsCommand.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            TotalSalesValue.Text = Convert.ToDecimal(reader.GetValue(0), CultureInfo.InvariantCulture).ToString("N2", CultureInfo.CurrentCulture);
                            TransactionsValue.Text = Convert.ToInt32(reader.GetValue(1), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                        }
                        if (reader.NextResult() && reader.Read())
                        {
                            ItemsSoldValue.Text = Convert.ToInt32(reader.GetValue(0), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                        }
                    }
                }

                BindDailySales(connection, weekStart, today.AddDays(1), today);
                BindProductPerformance(connection);
                BindRecentSales(connection, today);
                BindLowStock(connection);
            }
        }

        private void BindDailySales(SqlConnection connection, DateTime weekStart, DateTime endDate, DateTime today)
        {
            DataTable revenueByDay = new DataTable();
            revenueByDay.Columns.Add("SaleDate", typeof(DateTime));
            revenueByDay.Columns.Add("Revenue", typeof(decimal));
            using (SqlCommand command = new SqlCommand(@"SELECT CAST(TransactionDate AS date) AS SaleDate, SUM(NetAmount) AS Revenue
                                                         FROM SalesTransactions
                                                         WHERE TransactionDate >= @WeekStart AND TransactionDate < @EndDate
                                                         GROUP BY CAST(TransactionDate AS date);", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@WeekStart", SqlDbType.DateTime2).Value = weekStart;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                adapter.Fill(revenueByDay);
            }

            DataTable chart = new DataTable();
            chart.Columns.Add("DayLabel", typeof(string));
            chart.Columns.Add("BarHeight", typeof(int));
            chart.Columns.Add("Revenue", typeof(decimal));
            chart.Columns.Add("IsToday", typeof(bool));
            decimal maximum = 0m;
            foreach (DataRow row in revenueByDay.Rows)
            {
                maximum = Math.Max(maximum, Convert.ToDecimal(row["Revenue"], CultureInfo.InvariantCulture));
            }

            for (int offset = 0; offset < 7; offset++)
            {
                DateTime day = weekStart.AddDays(offset);
                decimal revenue = 0m;
                foreach (DataRow row in revenueByDay.Rows)
                {
                    if (Convert.ToDateTime(row["SaleDate"], CultureInfo.InvariantCulture).Date == day.Date)
                    {
                        revenue = Convert.ToDecimal(row["Revenue"], CultureInfo.InvariantCulture);
                        break;
                    }
                }

                int height = maximum == 0m ? 8 : Math.Max(8, (int)Math.Round((double)(revenue / maximum * 114m)));
                chart.Rows.Add(day.ToString("ddd", CultureInfo.CurrentCulture), height, revenue, day.Date == today.Date);
            }

            DailySalesRepeater.DataSource = chart;
            DailySalesRepeater.DataBind();
        }

        private void BindProductPerformance(SqlConnection connection)
        {
            using (SqlCommand command = new SqlCommand(@"SELECT TOP 4 ProductName, CategoryName, UnitPrice, TotalUnitsSold, TotalRevenue, TimesOrdered
                                                         FROM vw_ProductSalesSummary
                                                         ORDER BY TotalRevenue DESC, ProductName;", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                DataTable products = new DataTable();
                adapter.Fill(products);
                ProductPerformanceRepeater.DataSource = products;
                ProductPerformanceRepeater.DataBind();
            }
        }

        private void BindRecentSales(SqlConnection connection, DateTime today)
        {
            const string sql = @"SELECT TOP 4 '#' + RIGHT('0000' + CONVERT(VARCHAR(10), t.TransactionID), 4) AS FormattedID,
                                        t.TransactionDate, t.NetAmount,
                                        STUFF((SELECT ', ' + CONVERT(VARCHAR(10), i.QuantitySold) + N'× ' + p.ProductName
                                               FROM SalesTransactionItems i
                                               INNER JOIN Products p ON p.ProductID = i.ProductID
                                               WHERE i.TransactionID = t.TransactionID
                                               FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Items
                                 FROM SalesTransactions t
                                 ORDER BY t.TransactionDate DESC;";
            using (SqlCommand command = new SqlCommand(sql, connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                DataTable sales = new DataTable();
                adapter.Fill(sales);
                RecentSalesRepeater.DataSource = sales;
                RecentSalesRepeater.DataBind();
            }

            using (SqlCommand command = new SqlCommand("SELECT COUNT(*) FROM SalesTransactions WHERE TransactionDate >= @Today", connection))
            {
                command.Parameters.Add("@Today", SqlDbType.DateTime2).Value = today;
                TodayTransactionCount.Text = Convert.ToInt32(command.ExecuteScalar(), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
            }
        }

        private void BindLowStock(SqlConnection connection)
        {
            using (SqlCommand command = new SqlCommand("SELECT TOP 1 ProductName, StockQty FROM vw_LowStockAlert ORDER BY StockQty, ProductName", connection))
            using (SqlDataReader reader = command.ExecuteReader(CommandBehavior.SingleRow))
            {
                if (reader.Read())
                {
                    LowStockMessage.Text = Server.HtmlEncode(Convert.ToString(reader["ProductName"], CultureInfo.CurrentCulture)) +
                        " has " + Convert.ToString(reader["StockQty"], CultureInfo.CurrentCulture) + " servings left.";
                    LowStockPanel.Visible = true;
                }
            }
        }
    }
}
