using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Sales : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                BindSales();
            }
        }

        private void BindSales()
        {
            DateTime today = DateTime.Today;
            TodayDateText.Text = today.ToString("MMMM d, yyyy", CultureInfo.CurrentCulture);
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            using (SqlCommand summaryCommand = new SqlCommand(@"SELECT COUNT(*), ISNULL(SUM(NetAmount), 0), ISNULL(AVG(NetAmount), 0)
                                                                FROM SalesTransactions
                                                                WHERE TransactionDate >= @Today AND TransactionDate < @Tomorrow;", connection))
            {
                summaryCommand.Parameters.Add("@Today", SqlDbType.DateTime2).Value = today;
                summaryCommand.Parameters.Add("@Tomorrow", SqlDbType.DateTime2).Value = today.AddDays(1);
                connection.Open();
                using (SqlDataReader reader = summaryCommand.ExecuteReader(CommandBehavior.SingleRow))
                {
                    if (reader.Read())
                    {
                        int transactions = Convert.ToInt32(reader.GetValue(0), CultureInfo.InvariantCulture);
                        SalesTotalValue.Text = Convert.ToDecimal(reader.GetValue(1), CultureInfo.InvariantCulture).ToString("N2", CultureInfo.CurrentCulture);
                        TodayTransactionCount.Text = transactions.ToString("N0", CultureInfo.CurrentCulture);
                        AverageSaleValue.Text = Convert.ToDecimal(reader.GetValue(2), CultureInfo.InvariantCulture).ToString("N2", CultureInfo.CurrentCulture);
                    }
                }
            }

            const string sql = @"SELECT TOP 25
                                     '#' + RIGHT('0000' + CONVERT(VARCHAR(10), t.TransactionID), 4) AS FormattedID,
                                     t.TransactionDate, t.RecordedBy, t.PaymentMethod, t.NetAmount,
                                     STUFF((SELECT ', ' + CONVERT(VARCHAR(10), i.QuantitySold) + N'× ' + p.ProductName
                                            FROM SalesTransactionItems i
                                            INNER JOIN Products p ON p.ProductID = i.ProductID
                                            WHERE i.TransactionID = t.TransactionID
                                            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Items
                                 FROM SalesTransactions t
                                 ORDER BY t.TransactionDate DESC;";
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            using (SqlDataAdapter adapter = new SqlDataAdapter(sql, connection))
            {
                DataTable sales = new DataTable();
                adapter.Fill(sales);
                SalesRepeater.DataSource = sales;
                SalesRepeater.DataBind();
                SalesRowsText.Text = "Showing " + sales.Rows.Count.ToString("N0", CultureInfo.CurrentCulture) + " recent transactions";
            }
        }
    }
}
