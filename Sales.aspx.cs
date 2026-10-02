using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Sales : Page
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
                BindSaleProductDropdown();
                BindSalesSummary();
                BindSales();

                if (Request.QueryString["action"] == "new")
                {
                    OpenSaleModal();
                }
            }
        }

        private void BindSaleProductDropdown()
        {
            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand("SELECT ProductID, ProductName, UnitPrice, StockQty FROM Products WHERE UserID = @UserID AND IsActive = 1 AND StockQty > 0 ORDER BY ProductName;", connection))
            {
                connection.Open();
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    ddlSaleProduct.Items.Clear();
                    ddlSaleProduct.Items.Add(new ListItem("-- Select Available Food Product --", ""));

                    while (reader.Read())
                    {
                        string id = reader["ProductID"].ToString();
                        string name = reader["ProductName"].ToString();
                        decimal price = Convert.ToDecimal(reader["UnitPrice"], CultureInfo.InvariantCulture);
                        int stock = Convert.ToInt32(reader["StockQty"], CultureInfo.InvariantCulture);

                        string text = string.Format(CultureInfo.CurrentCulture, "{0} (₱{1:N2}) — {2} servings left", name, price, stock);
                        ddlSaleProduct.Items.Add(new ListItem(text, id));
                    }
                }
            }
        }

        private void BindSalesSummary()
        {
            DateTime today = DateTime.Today;
            TodayDateText.Text = today.ToString("MMMM d, yyyy", CultureInfo.CurrentCulture);

            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand summaryCommand = new SqlCommand(@"SELECT COUNT(*), ISNULL(SUM(NetAmount), 0), ISNULL(AVG(NetAmount), 0)
                                                                FROM SalesTransactions
                                                                WHERE UserID = @UserID AND TransactionDate >= @Today AND TransactionDate < @Tomorrow;", connection))
            {
                summaryCommand.Parameters.Add("@Today", SqlDbType.DateTime2).Value = today;
                summaryCommand.Parameters.Add("@Tomorrow", SqlDbType.DateTime2).Value = today.AddDays(1);
                connection.Open();
                summaryCommand.Parameters.Add("@UserID", SqlDbType.Int).Value = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
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
        }

        private void BindSales()
        {
            string search = txtSaleSearch.Text.Trim();
            string session = ddlSessionFilter.SelectedValue;
            string payment = ddlPaymentFilter.SelectedValue;

            string sql = @"SELECT TOP 50
                             '#' + RIGHT('0000' + CONVERT(VARCHAR(10), t.TransactionID), 4) AS FormattedID,
                             t.TransactionID,
                             t.TransactionDate,
                             t.SaleSession,
                             t.RecordedBy,
                             t.PaymentMethod,
                             t.NetAmount,
                             STUFF((SELECT ', ' + CONVERT(VARCHAR(10), i.QuantitySold) + N'× ' + p.ProductName
                                    FROM SalesTransactionItems i
                                    INNER JOIN Products p ON p.ProductID = i.ProductID
                                    WHERE i.TransactionID = t.TransactionID AND p.UserID = t.UserID
                                    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Items
                          FROM SalesTransactions t
                          WHERE t.UserID = @UserID";

            if (!string.IsNullOrEmpty(session))
            {
                sql += " AND t.SaleSession = @Session";
            }

            if (!string.IsNullOrEmpty(payment))
            {
                sql += " AND t.PaymentMethod = @PaymentMethod";
            }

            if (!string.IsNullOrEmpty(search))
            {
                sql += @" AND (t.RecordedBy LIKE @Search
                               OR ('#' + RIGHT('0000' + CONVERT(VARCHAR(10), t.TransactionID), 4)) LIKE @Search
                               OR EXISTS (SELECT 1 FROM SalesTransactionItems sti
                                          INNER JOIN Products sp ON sti.ProductID = sp.ProductID
                                          WHERE sti.TransactionID = t.TransactionID AND sp.UserID = t.UserID AND sp.ProductName LIKE @Search))";
            }

            sql += " ORDER BY t.TransactionDate DESC;";

            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                connection.Open();
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = Login.GetCurrentUserId(connection, Context.User.Identity.Name);

                if (!string.IsNullOrEmpty(session))
                {
                    command.Parameters.Add("@Session", SqlDbType.NVarChar, 50).Value = session;
                }

                if (!string.IsNullOrEmpty(payment))
                {
                    command.Parameters.Add("@PaymentMethod", SqlDbType.NVarChar, 50).Value = payment;
                }

                if (!string.IsNullOrEmpty(search))
                {
                    command.Parameters.Add("@Search", SqlDbType.NVarChar, 100).Value = "%" + search + "%";
                }

                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable sales = new DataTable();
                    adapter.Fill(sales);

                    SalesRepeater.DataSource = sales;
                    SalesRepeater.DataBind();

                    EmptySalesPanel.Visible = (sales.Rows.Count == 0);
                    SalesRowsText.Text = "Showing " + sales.Rows.Count.ToString("N0", CultureInfo.CurrentCulture) + " recent transactions from database";
                }
            }
        }

        protected void FilterSales(object sender, EventArgs e)
        {
            BindSales();
        }

        protected void BtnOpenRecordSale_Click(object sender, EventArgs e)
        {
            OpenSaleModal();
        }

        private void OpenSaleModal()
        {
            BindSaleProductDropdown();
            txtSaleQuantity.Text = "1";
            txtSaleDiscount.Text = "0.00";
            txtSaleCashier.Text = GetCurrentUserDisplayName();
            txtSaleNotes.Text = "";
            SaleErrorMessage.Visible = false;
            SaleModal.Visible = true;
        }

        protected void BtnCloseSaleModal_Click(object sender, EventArgs e)
        {
            SaleModal.Visible = false;
        }

        protected void BtnDismissSaleAlert_Click(object sender, EventArgs e)
        {
            SaleAlertPanel.Visible = false;
        }

        protected void BtnSubmitSale_Click(object sender, EventArgs e)
        {
            Page.Validate("SaleGroup");
            if (!Page.IsValid)
            {
                SaleModal.Visible = true;
                return;
            }

            if (!int.TryParse(ddlSaleProduct.SelectedValue, out int productId) || productId <= 0)
            {
                ShowSaleError("Please select a food product to sell.");
                return;
            }

            if (!int.TryParse(txtSaleQuantity.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out int qty) || qty <= 0)
            {
                ShowSaleError("Quantity sold must be at least 1.");
                return;
            }

            decimal discount = 0m;
            if (!string.IsNullOrWhiteSpace(txtSaleDiscount.Text))
            {
                decimal.TryParse(txtSaleDiscount.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out discount);
            }

            string session = ddlSaleSession.SelectedValue;
            string payment = ddlSalePaymentMethod.SelectedValue;
            string cashier = string.IsNullOrWhiteSpace(txtSaleCashier.Text) ? "Student Cashier" : txtSaleCashier.Text.Trim();
            string notes = string.IsNullOrWhiteSpace(txtSaleNotes.Text) ? null : txtSaleNotes.Text.Trim();

            try
            {
                using (SqlConnection connection = new SqlConnection(ConnectionString))
                {
                    connection.Open();

                    // Check stock
                    int currentStock = 0;
                    string productName = "";
                    decimal unitPrice = 0m;
                    int userId = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                    using (SqlCommand stockCmd = new SqlCommand("SELECT ProductName, UnitPrice, StockQty FROM Products WHERE ProductID = @ProductID AND UserID = @UserID AND IsActive = 1;", connection))
                    {
                        stockCmd.Parameters.Add("@ProductID", SqlDbType.Int).Value = productId;
                        stockCmd.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                        using (SqlDataReader reader = stockCmd.ExecuteReader())
                        {
                            if (!reader.Read())
                            {
                                ShowSaleError("Product was not found or is inactive.");
                                return;
                            }
                            productName = reader["ProductName"].ToString();
                            unitPrice = Convert.ToDecimal(reader["UnitPrice"], CultureInfo.InvariantCulture);
                            currentStock = Convert.ToInt32(reader["StockQty"], CultureInfo.InvariantCulture);
                        }
                    }

                    if (qty > currentStock)
                    {
                        ShowSaleError(string.Format("Insufficient stock! Only {0} servings of '{1}' remain available.", currentStock, productName));
                        return;
                    }

                    // Format JSON line items for atomic stored procedure
                    string itemsJson = string.Format(CultureInfo.InvariantCulture, "[{{\"ProductID\":{0},\"Qty\":{1}}}]", productId, qty);

                    using (SqlCommand saleCmd = new SqlCommand("usp_RecordSale", connection))
                    {
                        saleCmd.CommandType = CommandType.StoredProcedure;
                        saleCmd.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                        saleCmd.Parameters.Add("@SaleSession", SqlDbType.NVarChar, 50).Value = session;
                        saleCmd.Parameters.Add("@DiscountAmount", SqlDbType.Decimal).Value = discount;
                        saleCmd.Parameters.Add("@PaymentMethod", SqlDbType.NVarChar, 50).Value = payment;
                        saleCmd.Parameters.Add("@RecordedBy", SqlDbType.NVarChar, 100).Value = cashier;
                        saleCmd.Parameters.Add("@Notes", SqlDbType.NVarChar, 500).Value = (object)notes ?? DBNull.Value;
                        saleCmd.Parameters.Add("@ItemsJSON", SqlDbType.NVarChar, -1).Value = itemsJson;

                        SqlParameter outIdParam = new SqlParameter("@NewTransactionID", SqlDbType.Int)
                        {
                            Direction = ParameterDirection.Output
                        };
                        saleCmd.Parameters.Add(outIdParam);

                        saleCmd.ExecuteNonQuery();

                        int newTransactionId = Convert.ToInt32(outIdParam.Value, CultureInfo.InvariantCulture);
                        decimal lineTotal = (unitPrice * qty) - discount;

                        SaleModal.Visible = false;
                        ShowSaleAlert(string.Format("✓ Transaction #{0:0000} recorded successfully! Sold {1}× {2} for ₱{3:N2}. Stock was deducted in SQL.",
                            newTransactionId, qty, productName, lineTotal), false);

                        BindSaleProductDropdown();
                        BindSalesSummary();
                        BindSales();
                    }
                }
            }
            catch (SqlException ex)
            {
                ShowSaleError("Database error while recording sale: " + ex.Message);
            }
        }

        private string GetCurrentUserDisplayName()
        {
            if (!Context.User.Identity.IsAuthenticated)
            {
                return "Student Cashier";
            }

            try
            {
                using (SqlConnection connection = new SqlConnection(ConnectionString))
                using (SqlCommand command = new SqlCommand("SELECT DisplayName FROM AppUsers WHERE Username = @Username AND IsActive = 1;", connection))
                {
                    command.Parameters.AddWithValue("@Username", Context.User.Identity.Name);
                    connection.Open();
                    object result = command.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        return Convert.ToString(result);
                    }
                }
            }
            catch
            {
                // Fallback to identity name
            }

            return Context.User.Identity.Name;
        }

        private void ShowSaleError(string message)
        {
            SaleErrorMessage.Text = message;
            SaleErrorMessage.Visible = true;
            SaleModal.Visible = true;
        }

        private void ShowSaleAlert(string message, bool isError)
        {
            SaleAlertMessage.Text = message;
            SaleAlertPanel.CssClass = isError ? "alert-banner alert-error" : "alert-banner alert-success";
            SaleAlertPanel.Visible = true;
        }
    }
}
