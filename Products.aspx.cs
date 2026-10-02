using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Products : Page
    {
        private static string ConnectionString
        {
            get
            {
                ConnectionStringSettings settings = ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"];
                if (settings == null)
                {
                    throw new ConfigurationErrorsException("The CafeteriaFoodTrackerDB connection string is missing.");
                }
                return settings.ConnectionString;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                BindCategoryDropdowns();
                BindSummaryMetrics();
                BindProducts();
            }
        }

        private void BindCategoryDropdowns()
        {
            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand("SELECT CategoryID, CategoryName FROM Categories WHERE IsActive = 1 ORDER BY CategoryName;", connection))
            {
                connection.Open();
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    ddlCategoryFilter.Items.Clear();
                    ddlCategoryFilter.Items.Add(new ListItem("All categories", ""));

                    ddlModalCategory.Items.Clear();
                    ddlModalCategory.Items.Add(new ListItem("-- Select Category --", ""));

                    while (reader.Read())
                    {
                        string id = reader["CategoryID"].ToString();
                        string name = reader["CategoryName"].ToString();
                        ddlCategoryFilter.Items.Add(new ListItem(name, id));
                        ddlModalCategory.Items.Add(new ListItem(name, id));
                    }
                }
            }
        }

        private void BindSummaryMetrics()
        {
            const string sql = @"SELECT (SELECT COUNT(*) FROM Products WHERE UserID = @UserID),
                                        (SELECT COUNT(*) FROM Products WHERE UserID = @UserID AND IsActive = 1),
                                        (SELECT COUNT(DISTINCT CategoryID) FROM Products WHERE UserID = @UserID AND IsActive = 1),
                                        (SELECT COUNT(*) FROM vw_LowStockAlert WHERE UserID = @UserID);";

            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                connection.Open();
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                using (SqlDataReader reader = command.ExecuteReader(CommandBehavior.SingleRow))
                {
                    if (reader.Read())
                    {
                        TotalProductsValue.Text = Convert.ToInt32(reader.GetValue(0), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                        ActiveProductsValue.Text = Convert.ToInt32(reader.GetValue(1), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                        CategoryCountValue.Text = Convert.ToInt32(reader.GetValue(2), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                        LowStockProductsValue.Text = Convert.ToInt32(reader.GetValue(3), CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                    }
                }
            }
        }

        private void BindProducts()
        {
            string search = txtSearch.Text.Trim();
            string categoryIdStr = ddlCategoryFilter.SelectedValue;
            string stockFilter = ddlStockFilter.SelectedValue;

            string sql = @"SELECT ProductID, CategoryID, ProductName, REPLACE(REPLACE(Description, NCHAR(194) + NCHAR(183), N''), NCHAR(194), N'') AS Description, CategoryName,
                                  UnitPrice, CostPrice, StockQty, ReorderLevel, TotalUnitsSold, TotalRevenue
                           FROM vw_ProductSalesSummary
                           WHERE UserID = @UserID AND IsActive = 1";

            if (!string.IsNullOrEmpty(categoryIdStr))
            {
                sql += " AND CategoryID = @CategoryID";
            }

            if (!string.IsNullOrEmpty(search))
            {
                sql += " AND (ProductName LIKE @Search OR CategoryName LIKE @Search OR ISNULL(Description, '') LIKE @Search)";
            }

            if (stockFilter == "InStock")
            {
                sql += " AND StockQty > ReorderLevel";
            }
            else if (stockFilter == "LowStock")
            {
                sql += " AND StockQty <= ReorderLevel AND StockQty > 0";
            }
            else if (stockFilter == "SoldOut")
            {
                sql += " AND StockQty = 0";
            }

            sql += " ORDER BY ProductName;";

            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                connection.Open();
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = Login.GetCurrentUserId(connection, Context.User.Identity.Name);

                if (!string.IsNullOrEmpty(categoryIdStr) && int.TryParse(categoryIdStr, out int catId))
                {
                    command.Parameters.Add("@CategoryID", SqlDbType.Int).Value = catId;
                }

                if (!string.IsNullOrEmpty(search))
                {
                    command.Parameters.Add("@Search", SqlDbType.NVarChar, 150).Value = "%" + search + "%";
                }

                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable products = new DataTable();
                    adapter.Fill(products);

                    ProductRepeater.DataSource = products;
                    ProductRepeater.DataBind();

                    EmptyProductsPanel.Visible = (products.Rows.Count == 0);
                    ProductCountText.Text = "Showing " + products.Rows.Count.ToString("N0", CultureInfo.CurrentCulture) + " products";
                }
            }
        }

        protected void FilterChanged(object sender, EventArgs e)
        {
            BindProducts();
        }

        protected void BtnOpenAddProduct_Click(object sender, EventArgs e)
        {
            hfProductID.Value = "";
            txtProductName.Text = "";
            if (ddlModalCategory.Items.Count > 0)
            {
                ddlModalCategory.SelectedIndex = 0;
            }
            txtUnitPrice.Text = "";
            txtCostPrice.Text = "0.00";
            txtStockQty.Text = "0";
            txtReorderLevel.Text = "5";
            txtDescription.Text = "";

            ModalTitle.Text = "Add New Product";
            btnSaveProduct.Text = "Save to Database";
            ModalErrorMessage.Visible = false;
            ProductModal.Visible = true;
        }

        protected void BtnCloseModal_Click(object sender, EventArgs e)
        {
            ProductModal.Visible = false;
        }

        protected void BtnDismissAlert_Click(object sender, EventArgs e)
        {
            AlertPanel.Visible = false;
        }

        protected void BtnSaveProduct_Click(object sender, EventArgs e)
        {
            Page.Validate("ProductGroup");
            if (!Page.IsValid)
            {
                ProductModal.Visible = true;
                return;
            }

            string productName = txtProductName.Text.Trim();
            if (string.IsNullOrEmpty(productName))
            {
                ShowModalError("Product name is required.");
                return;
            }

            if (!int.TryParse(ddlModalCategory.SelectedValue, out int categoryId) || categoryId <= 0)
            {
                ShowModalError("Please select a valid food category.");
                return;
            }

            if (!decimal.TryParse(txtUnitPrice.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out decimal unitPrice) || unitPrice <= 0)
            {
                ShowModalError("Please enter a valid selling price greater than 0.");
                return;
            }

            decimal costPrice = 0m;
            if (!string.IsNullOrWhiteSpace(txtCostPrice.Text))
            {
                decimal.TryParse(txtCostPrice.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out costPrice);
            }

            if (!int.TryParse(txtStockQty.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out int stockQty) || stockQty < 0)
            {
                ShowModalError("Stock quantity must be a non-negative whole number.");
                return;
            }

            if (!int.TryParse(txtReorderLevel.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out int reorderLevel) || reorderLevel < 0)
            {
                reorderLevel = 5;
            }

            string description = string.IsNullOrWhiteSpace(txtDescription.Text) ? null : txtDescription.Text.Trim();

            int? productId = null;
            if (int.TryParse(hfProductID.Value, out int pid) && pid > 0)
            {
                productId = pid;
            }

            try
            {
                using (SqlConnection connection = new SqlConnection(ConnectionString))
                using (SqlCommand command = new SqlCommand("usp_UpsertProduct", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add("@ProductID", SqlDbType.Int).Value = productId.HasValue ? (object)productId.Value : DBNull.Value;
                    command.Parameters.Add("@CategoryID", SqlDbType.Int).Value = categoryId;
                    command.Parameters.Add("@ProductName", SqlDbType.NVarChar, 150).Value = productName;
                    command.Parameters.Add("@Description", SqlDbType.NVarChar, 500).Value = (object)description ?? DBNull.Value;
                    command.Parameters.Add("@UnitPrice", SqlDbType.Decimal).Value = unitPrice;
                    command.Parameters.Add("@CostPrice", SqlDbType.Decimal).Value = costPrice;
                    command.Parameters.Add("@StockQty", SqlDbType.Int).Value = stockQty;
                    command.Parameters.Add("@ReorderLevel", SqlDbType.Int).Value = reorderLevel;
                    command.Parameters.Add("@ImageURL", SqlDbType.NVarChar, 500).Value = DBNull.Value;
                    command.Parameters.Add("@IsActive", SqlDbType.Bit).Value = true;

                    connection.Open();
                    command.Parameters.Add("@UserID", SqlDbType.Int).Value = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                    object savedId = command.ExecuteScalar();
                }

                ProductModal.Visible = false;
                ShowAlert("Product '" + Server.HtmlEncode(productName) + "' was successfully saved to Microsoft SQL Server database.", false);
                BindSummaryMetrics();
                BindProducts();
            }
            catch (SqlException ex)
            {
                ShowModalError("Database error while saving product: " + ex.Message);
            }
        }

        protected void ProductRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out int productId))
            {
                return;
            }

            if (e.CommandName == "EditProduct")
            {
                try
                {
                    using (SqlConnection connection = new SqlConnection(ConnectionString))
                    using (SqlCommand command = new SqlCommand("SELECT ProductID, CategoryID, ProductName, Description, UnitPrice, CostPrice, StockQty, ReorderLevel FROM Products WHERE ProductID = @ProductID AND UserID = @UserID;", connection))
                    {
                        command.Parameters.Add("@ProductID", SqlDbType.Int).Value = productId;
                        connection.Open();
                        command.Parameters.Add("@UserID", SqlDbType.Int).Value = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                        using (SqlDataReader reader = command.ExecuteReader(CommandBehavior.SingleRow))
                        {
                            if (reader.Read())
                            {
                                hfProductID.Value = reader["ProductID"].ToString();
                                txtProductName.Text = reader["ProductName"].ToString();
                                string catId = reader["CategoryID"].ToString();
                                if (ddlModalCategory.Items.FindByValue(catId) != null)
                                {
                                    ddlModalCategory.SelectedValue = catId;
                                }
                                txtUnitPrice.Text = Convert.ToDecimal(reader["UnitPrice"], CultureInfo.InvariantCulture).ToString("F2", CultureInfo.InvariantCulture);
                                txtCostPrice.Text = Convert.ToDecimal(reader["CostPrice"], CultureInfo.InvariantCulture).ToString("F2", CultureInfo.InvariantCulture);
                                txtStockQty.Text = reader["StockQty"].ToString();
                                txtReorderLevel.Text = reader["ReorderLevel"].ToString();
                                txtDescription.Text = reader["Description"] == DBNull.Value ? "" : reader["Description"].ToString();

                                ModalTitle.Text = "Edit Product: " + Server.HtmlEncode(txtProductName.Text);
                                btnSaveProduct.Text = "Update Product in SQL";
                                ModalErrorMessage.Visible = false;
                                ProductModal.Visible = true;
                            }
                        }
                    }
                }
                catch (SqlException ex)
                {
                    ShowAlert("Error loading product details: " + ex.Message, true);
                }
            }
            else if (e.CommandName == "DeleteProduct")
            {
                try
                {
                    using (SqlConnection connection = new SqlConnection(ConnectionString))
                    using (SqlCommand command = new SqlCommand("usp_DeleteProduct", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        connection.Open();
                        command.Parameters.Add("@UserID", SqlDbType.Int).Value = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                        command.Parameters.Add("@ProductID", SqlDbType.Int).Value = productId;
                        command.ExecuteNonQuery();
                    }

                    ShowAlert("Product was successfully deactivated in SQL Server.", false);
                    BindSummaryMetrics();
                    BindProducts();
                }
                catch (SqlException ex)
                {
                    ShowAlert("Error deactivating product: " + ex.Message, true);
                }
            }
        }

        private void ShowModalError(string message)
        {
            ModalErrorMessage.Text = message;
            ModalErrorMessage.Visible = true;
            ProductModal.Visible = true;
        }

        private void ShowAlert(string message, bool isError)
        {
            AlertMessage.Text = message;
            AlertPanel.CssClass = isError ? "alert-banner alert-error" : "alert-banner alert-success";
            AlertPanel.Visible = true;
        }
    }
}
