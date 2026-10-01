using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Analytics : Page
    {
        protected void Page_Load(object sender, System.EventArgs e)
        {
            if (!IsPostBack)
            {
                BindAnalytics();
            }
        }

        private void BindAnalytics()
        {
            DateTime today = DateTime.Today;
            DateTime startDate = today.AddDays(-6);
            DateTime endDate = today.AddDays(1);
            DateRangeText.Text = startDate.ToString("MMM d", CultureInfo.CurrentCulture) + "–" + today.ToString("MMM d, yyyy", CultureInfo.CurrentCulture);

            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            {
                connection.Open();
                BindTrend(connection, startDate, endDate, today);
                BindSummary(connection, startDate, endDate);
                BindTopProducts(connection, startDate, endDate);
                BindTodayActivity(connection, today, endDate);
            }
        }

        private void BindTrend(SqlConnection connection, DateTime startDate, DateTime endDate, DateTime today)
        {
            DataTable dailyTotals = new DataTable();
            using (SqlCommand command = new SqlCommand(@"SELECT CAST(TransactionDate AS date) AS SaleDate,
                                                               SUM(NetAmount) AS Revenue,
                                                               COUNT(*) AS Transactions
                                                        FROM SalesTransactions
                                                        WHERE TransactionDate >= @StartDate AND TransactionDate < @EndDate
                                                        GROUP BY CAST(TransactionDate AS date);", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@StartDate", SqlDbType.DateTime2).Value = startDate;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                adapter.Fill(dailyTotals);
            }

            decimal maximum = 0m;
            decimal totalRevenue = 0m;
            int transactionCount = 0;
            DateTime bestDay = startDate;
            foreach (DataRow row in dailyTotals.Rows)
            {
                decimal revenue = Convert.ToDecimal(row["Revenue"], CultureInfo.InvariantCulture);
                totalRevenue += revenue;
                transactionCount += Convert.ToInt32(row["Transactions"], CultureInfo.InvariantCulture);
                if (revenue > maximum)
                {
                    maximum = revenue;
                    bestDay = Convert.ToDateTime(row["SaleDate"], CultureInfo.InvariantCulture);
                }
            }

            DataTable chart = new DataTable();
            chart.Columns.Add("DayLabel", typeof(string));
            chart.Columns.Add("BarHeight", typeof(int));
            chart.Columns.Add("Revenue", typeof(decimal));
            chart.Columns.Add("IsToday", typeof(bool));
            for (int offset = 0; offset < 7; offset++)
            {
                DateTime day = startDate.AddDays(offset);
                decimal revenue = 0m;
                foreach (DataRow row in dailyTotals.Rows)
                {
                    if (Convert.ToDateTime(row["SaleDate"], CultureInfo.InvariantCulture).Date == day.Date)
                    {
                        revenue = Convert.ToDecimal(row["Revenue"], CultureInfo.InvariantCulture);
                        break;
                    }
                }

                int barHeight = maximum == 0m ? 8 : Math.Max(8, (int)Math.Round((double)(revenue / maximum * 114m)));
                chart.Rows.Add(day.ToString("ddd", CultureInfo.CurrentCulture), barHeight, revenue, day.Date == today.Date);
            }

            DailySalesRepeater.DataSource = chart;
            DailySalesRepeater.DataBind();
            TotalRevenueValue.Text = totalRevenue.ToString("N2", CultureInfo.CurrentCulture);
            WeeklyTransactionCount.Text = transactionCount.ToString("N0", CultureInfo.CurrentCulture);
            BestSalesDayText.Text = maximum == 0m
                ? "No sales recorded during this period."
                : Server.HtmlEncode(bestDay.ToString("dddd", CultureInfo.CurrentCulture)) + " generated the most revenue at &#8369;" + maximum.ToString("N2", CultureInfo.CurrentCulture) + ".";
        }

        private void BindSummary(SqlConnection connection, DateTime startDate, DateTime endDate)
        {
            using (SqlCommand command = new SqlCommand(@"SELECT ISNULL(SUM(i.QuantitySold), 0)
                                                        FROM SalesTransactionItems i
                                                        INNER JOIN SalesTransactions t ON t.TransactionID = i.TransactionID
                                                        WHERE t.TransactionDate >= @StartDate AND t.TransactionDate < @EndDate;", connection))
            {
                command.Parameters.Add("@StartDate", SqlDbType.DateTime2).Value = startDate;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                ItemsSoldValue.Text = Convert.ToInt32(command.ExecuteScalar(), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
            }

            using (SqlCommand command = new SqlCommand(@"SELECT TOP 1 p.ProductName, SUM(i.QuantitySold) AS UnitsSold
                                                        FROM SalesTransactionItems i
                                                        INNER JOIN SalesTransactions t ON t.TransactionID = i.TransactionID
                                                        INNER JOIN Products p ON p.ProductID = i.ProductID
                                                        WHERE t.TransactionDate >= @StartDate AND t.TransactionDate < @EndDate
                                                        GROUP BY p.ProductName
                                                        ORDER BY UnitsSold DESC, p.ProductName;", connection))
            {
                command.Parameters.Add("@StartDate", SqlDbType.DateTime2).Value = startDate;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                using (SqlDataReader reader = command.ExecuteReader(CommandBehavior.SingleRow))
                {
                    if (reader.Read())
                    {
                        BestSellerName.Text = Server.HtmlEncode(Convert.ToString(reader["ProductName"], CultureInfo.CurrentCulture));
                        BestSellerUnits.Text = Convert.ToInt32(reader["UnitsSold"], CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                        TopPerformerText.Text = BestSellerName.Text + " leads with " + BestSellerUnits.Text + " units sold.";
                    }
                    else
                    {
                        BestSellerName.Text = "No sales yet";
                        BestSellerUnits.Text = "0";
                        TopPerformerText.Text = "No product sales recorded during this period.";
                    }
                }
            }
        }

        private void BindTopProducts(SqlConnection connection, DateTime startDate, DateTime endDate)
        {
            using (SqlCommand command = new SqlCommand(@"SELECT TOP 4 p.ProductName,
                                                               SUM(i.QuantitySold) AS UnitsSold,
                                                               SUM(i.LineTotal) AS Revenue
                                                        FROM SalesTransactionItems i
                                                        INNER JOIN SalesTransactions t ON t.TransactionID = i.TransactionID
                                                        INNER JOIN Products p ON p.ProductID = i.ProductID
                                                        WHERE t.TransactionDate >= @StartDate AND t.TransactionDate < @EndDate
                                                        GROUP BY p.ProductName
                                                        ORDER BY Revenue DESC, p.ProductName;", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@StartDate", SqlDbType.DateTime2).Value = startDate;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                DataTable products = new DataTable();
                adapter.Fill(products);
                TopProductsRepeater.DataSource = products;
                TopProductsRepeater.DataBind();
            }
        }

        private void BindTodayActivity(SqlConnection connection, DateTime today, DateTime endDate)
        {
            using (SqlCommand command = new SqlCommand("SELECT COUNT(*) FROM SalesTransactions WHERE TransactionDate >= @Today AND TransactionDate < @EndDate", connection))
            {
                command.Parameters.Add("@Today", SqlDbType.DateTime2).Value = today;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                int count = Convert.ToInt32(command.ExecuteScalar(), CultureInfo.InvariantCulture);
                TodayActivityText.Text = count.ToString("N0", CultureInfo.CurrentCulture) + (count == 1 ? " transaction recorded today." : " transactions recorded today.");
            }
        }
    }
}
