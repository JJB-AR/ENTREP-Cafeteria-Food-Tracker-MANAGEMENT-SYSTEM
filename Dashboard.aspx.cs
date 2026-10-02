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
                int userId = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                using (SqlCommand userCommand = new SqlCommand("SELECT DisplayName FROM AppUsers WHERE UserID = @UserID AND IsActive = 1", connection))
                {
                    userCommand.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                    object name = userCommand.ExecuteScalar();
                    if (name != null && name != DBNull.Value)
                    {
                        UserDisplayName.Text = Server.HtmlEncode(Convert.ToString(name, CultureInfo.CurrentCulture));
                    }
                }

                const string metricsSql = @"SELECT ISNULL(SUM(NetAmount), 0), COUNT(TransactionID)
                                            FROM SalesTransactions WHERE UserID = @UserID AND TransactionDate >= @Today;
                                            SELECT ISNULL(SUM(i.QuantitySold), 0)
                                            FROM SalesTransactionItems i
                                            INNER JOIN SalesTransactions t ON t.TransactionID = i.TransactionID
                                            WHERE t.UserID = @UserID AND t.TransactionDate >= @Today;";
                using (SqlCommand metricsCommand = new SqlCommand(metricsSql, connection))
                {
                    metricsCommand.Parameters.Add("@Today", SqlDbType.DateTime2).Value = today;
                    metricsCommand.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
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

                BindDailySales(connection, userId, weekStart, today.AddDays(1), today);
                BindProductPerformance(connection, userId);
                BindRecentSales(connection, userId, today);
                BindLowStock(connection, userId);
            }
        }

        private void BindDailySales(SqlConnection connection, int userId, DateTime weekStart, DateTime endDate, DateTime today)
        {
            DataTable revenueByDay = new DataTable();
            revenueByDay.Columns.Add("SaleDate", typeof(DateTime));
            revenueByDay.Columns.Add("Revenue", typeof(decimal));
            using (SqlCommand command = new SqlCommand(@"SELECT CAST(TransactionDate AS date) AS SaleDate, SUM(NetAmount) AS Revenue
                                                         FROM SalesTransactions
                                                         WHERE UserID = @UserID AND TransactionDate >= @WeekStart AND TransactionDate < @EndDate
                                                         GROUP BY CAST(TransactionDate AS date);", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@WeekStart", SqlDbType.DateTime2).Value = weekStart;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
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

        private void BindProductPerformance(SqlConnection connection, int userId)
        {
            using (SqlCommand command = new SqlCommand(@"SELECT TOP 4 ProductName, CategoryName, UnitPrice, TotalUnitsSold, TotalRevenue, TimesOrdered
                                                         FROM vw_ProductSalesSummary
                                                         WHERE UserID = @UserID
                                                         ORDER BY TotalRevenue DESC, ProductName;", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                DataTable products = new DataTable();
                adapter.Fill(products);
                ProductPerformanceRepeater.DataSource = products;
                ProductPerformanceRepeater.DataBind();
            }
        }

        private void BindRecentSales(SqlConnection connection, int userId, DateTime today)
        {
            const string sql = @"SELECT TOP 4 '#' + RIGHT('0000' + CONVERT(VARCHAR(10), t.TransactionID), 4) AS FormattedID,
                                        t.TransactionDate, t.NetAmount,
                                        STUFF((SELECT ', ' + CONVERT(VARCHAR(10), i.QuantitySold) + N'× ' + p.ProductName
                                               FROM SalesTransactionItems i
                                               INNER JOIN Products p ON p.ProductID = i.ProductID
                                               WHERE i.TransactionID = t.TransactionID AND p.UserID = t.UserID
                                               FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Items
                                 FROM SalesTransactions t
                                 WHERE t.UserID = @UserID
                                 ORDER BY t.TransactionDate DESC;";
            using (SqlCommand command = new SqlCommand(sql, connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                DataTable sales = new DataTable();
                adapter.Fill(sales);
                RecentSalesRepeater.DataSource = sales;
                RecentSalesRepeater.DataBind();
            }

            using (SqlCommand command = new SqlCommand("SELECT COUNT(*) FROM SalesTransactions WHERE UserID = @UserID AND TransactionDate >= @Today", connection))
            {
                command.Parameters.Add("@Today", SqlDbType.DateTime2).Value = today;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                TodayTransactionCount.Text = Convert.ToInt32(command.ExecuteScalar(), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
            }
        }

        private void BindLowStock(SqlConnection connection, int userId)
        {
            using (SqlCommand command = new SqlCommand("SELECT TOP 1 ProductName, StockQty FROM vw_LowStockAlert WHERE UserID = @UserID ORDER BY StockQty, ProductName", connection))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
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
}
