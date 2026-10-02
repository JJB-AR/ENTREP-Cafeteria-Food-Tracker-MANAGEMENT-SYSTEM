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
                DateTime today;
                using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
                using (SqlCommand command = new SqlCommand("SELECT CAST(SYSDATETIME() AS date);", connection))
                {
                    connection.Open();
                    today = Convert.ToDateTime(command.ExecuteScalar(), CultureInfo.InvariantCulture);
                }

                StartDateInput.Text = today.AddDays(-6).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                EndDateInput.Text = today.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                BindAnalytics();
            }
        }

        protected void ApplyDateRangeButton_Click(object sender, EventArgs e)
        {
            BindAnalytics();
        }

        private void BindAnalytics()
        {
            DateTime startDate;
            DateTime selectedEndDate;
            if (!DateTime.TryParseExact(StartDateInput.Text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out startDate) ||
                !DateTime.TryParseExact(EndDateInput.Text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out selectedEndDate))
            {
                DateRangeError.Text = "Choose a valid start date and end date.";
                DateRangeError.Visible = true;
                return;
            }

            if (startDate.Date > selectedEndDate.Date)
            {
                DateRangeError.Text = "The start date must be on or before the end date.";
                DateRangeError.Visible = true;
                return;
            }

            if (selectedEndDate.Date == DateTime.MaxValue.Date)
            {
                DateRangeError.Text = "Choose an end date before December 31, 9999.";
                DateRangeError.Visible = true;
                return;
            }

            startDate = startDate.Date;
            selectedEndDate = selectedEndDate.Date;
            DateTime endDate = selectedEndDate.AddDays(1);
            DateRangeError.Visible = false;

            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            {
                connection.Open();

                DateTime today;
                using (SqlCommand command = new SqlCommand("SELECT CAST(SYSDATETIME() AS date);", connection))
                {
                    today = Convert.ToDateTime(command.ExecuteScalar(), CultureInfo.InvariantCulture);
                }

                int userId = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                DateRangeText.Text = startDate.ToString("MMM d, yyyy", CultureInfo.CurrentCulture) + "–" + selectedEndDate.ToString("MMM d, yyyy", CultureInfo.CurrentCulture);

                BindTrend(connection, userId, startDate, endDate, today);
                BindSummary(connection, userId, startDate, endDate);
                BindTopProducts(connection, userId, startDate, endDate);
                BindTodayActivity(connection, userId, today, today.AddDays(1));
            }
        }

        private void BindTrend(SqlConnection connection, int userId, DateTime startDate, DateTime endDate, DateTime today)
        {
            DataTable dailyTotals = new DataTable();
            using (SqlCommand command = new SqlCommand(@"SELECT CAST(TransactionDate AS date) AS SaleDate,
                                                               SUM(NetAmount) AS Revenue,
                                                               COUNT(*) AS Transactions
                                                        FROM SalesTransactions
                                                        WHERE UserID = @UserID AND TransactionDate >= @StartDate AND TransactionDate < @EndDate
                                                        GROUP BY CAST(TransactionDate AS date);", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@StartDate", SqlDbType.DateTime2).Value = startDate;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
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
            int dayCount = (int)(endDate - startDate).TotalDays;
            for (int offset = 0; offset < dayCount; offset++)
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
                chart.Rows.Add(day.ToString("MMM d", CultureInfo.CurrentCulture), barHeight, revenue, day.Date == today.Date);
            }

            DailySalesRepeater.DataSource = chart;
            DailySalesRepeater.DataBind();
            TotalRevenueValue.Text = totalRevenue.ToString("N2", CultureInfo.CurrentCulture);
            WeeklyTransactionCount.Text = transactionCount.ToString("N0", CultureInfo.CurrentCulture);
            BestSalesDayText.Text = maximum == 0m
                ? "No sales recorded during this period."
                : Server.HtmlEncode(bestDay.ToString("dddd", CultureInfo.CurrentCulture)) + " generated the most revenue at &#8369;" + maximum.ToString("N2", CultureInfo.CurrentCulture) + ".";
        }

        private void BindSummary(SqlConnection connection, int userId, DateTime startDate, DateTime endDate)
        {
            using (SqlCommand command = new SqlCommand(@"SELECT ISNULL(SUM(i.QuantitySold), 0)
                                                        FROM SalesTransactionItems i
                                                        INNER JOIN SalesTransactions t ON t.TransactionID = i.TransactionID
                                                        WHERE t.UserID = @UserID AND t.TransactionDate >= @StartDate AND t.TransactionDate < @EndDate;", connection))
            {
                command.Parameters.Add("@StartDate", SqlDbType.DateTime2).Value = startDate;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                ItemsSoldValue.Text = Convert.ToInt32(command.ExecuteScalar(), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
            }

            using (SqlCommand command = new SqlCommand(@"SELECT TOP 1 p.ProductName, SUM(i.QuantitySold) AS UnitsSold
                                                        FROM SalesTransactionItems i
                                                        INNER JOIN SalesTransactions t ON t.TransactionID = i.TransactionID
                                                        INNER JOIN Products p ON p.ProductID = i.ProductID
                                                        WHERE t.UserID = @UserID AND p.UserID = t.UserID AND t.TransactionDate >= @StartDate AND t.TransactionDate < @EndDate
                                                        GROUP BY p.ProductID, p.ProductName
                                                        ORDER BY UnitsSold DESC, p.ProductName;", connection))
            {
                command.Parameters.Add("@StartDate", SqlDbType.DateTime2).Value = startDate;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
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

        private void BindTopProducts(SqlConnection connection, int userId, DateTime startDate, DateTime endDate)
        {
            using (SqlCommand command = new SqlCommand(@"SELECT TOP 4 p.ProductName,
                                                               SUM(i.QuantitySold) AS UnitsSold,
                                                               SUM(i.LineTotal) AS Revenue
                                                        FROM SalesTransactionItems i
                                                        INNER JOIN SalesTransactions t ON t.TransactionID = i.TransactionID
                                                        INNER JOIN Products p ON p.ProductID = i.ProductID
                                                        WHERE t.UserID = @UserID AND p.UserID = t.UserID AND t.TransactionDate >= @StartDate AND t.TransactionDate < @EndDate
                                                        GROUP BY p.ProductID, p.ProductName
                                                        ORDER BY Revenue DESC, p.ProductName;", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@StartDate", SqlDbType.DateTime2).Value = startDate;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                DataTable products = new DataTable();
                adapter.Fill(products);
                TopProductsRepeater.DataSource = products;
                TopProductsRepeater.DataBind();
            }
        }

        private void BindTodayActivity(SqlConnection connection, int userId, DateTime today, DateTime endDate)
        {
            using (SqlCommand command = new SqlCommand("SELECT COUNT(*) FROM SalesTransactions WHERE UserID = @UserID AND TransactionDate >= @Today AND TransactionDate < @EndDate", connection))
            {
                command.Parameters.Add("@Today", SqlDbType.DateTime2).Value = today;
                command.Parameters.Add("@EndDate", SqlDbType.DateTime2).Value = endDate;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                int count = Convert.ToInt32(command.ExecuteScalar(), CultureInfo.InvariantCulture);
                TodayActivityText.Text = count.ToString("N0", CultureInfo.CurrentCulture) + (count == 1 ? " transaction recorded today." : " transactions recorded today.");
            }
        }
    }
}
