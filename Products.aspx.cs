using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Products : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                BindProducts();
            }
        }

        private void BindProducts()
        {
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            using (SqlCommand command = new SqlCommand(@"SELECT (SELECT COUNT(*) FROM Products),
                                                               (SELECT COUNT(*) FROM Products WHERE IsActive = 1),
                                                               (SELECT COUNT(DISTINCT CategoryID) FROM Products WHERE IsActive = 1),
                                                               (SELECT COUNT(*) FROM vw_LowStockAlert);", connection))
            {
                connection.Open();
                using (SqlDataReader reader = command.ExecuteReader(CommandBehavior.SingleRow))
                {
                    if (reader.Read())
                    {
                        TotalProductsValue.Text = Convert.ToInt32(reader.GetValue(0)).ToString("N0");
                        ActiveProductsValue.Text = Convert.ToInt32(reader.GetValue(1)).ToString("N0");
                        CategoryCountValue.Text = Convert.ToInt32(reader.GetValue(2)).ToString("N0");
                        LowStockProductsValue.Text = Convert.ToInt32(reader.GetValue(3)).ToString("N0");
                    }
                }
            }

            const string sql = @"SELECT ProductName, CategoryName, UnitPrice, StockQty, ReorderLevel,
                                        TotalUnitsSold, TotalRevenue
                                 FROM vw_ProductSalesSummary
                                 ORDER BY ProductName;";
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            using (SqlDataAdapter adapter = new SqlDataAdapter(sql, connection))
            {
                DataTable products = new DataTable();
                adapter.Fill(products);
                ProductRepeater.DataSource = products;
                ProductRepeater.DataBind();
                ProductCountText.Text = "Showing " + products.Rows.Count.ToString("N0") + " active products";
            }
        }
    }
}
