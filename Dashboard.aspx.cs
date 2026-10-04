using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Dashboard : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            int userId;
            bool isAdmin;
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            {
                connection.Open();
                userId = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                isAdmin = Login.IsAdministrator(connection, userId);
                AdminManagementPanel.Visible = isAdmin;
                SalesDashboardPanel.Visible = !isAdmin;
                if (isAdmin)
                {
                    DashboardLayout.Attributes["class"] += " admin-dashboard";
                }

                if (isAdmin && !IsPostBack)
                {
                    BindUsers(connection, userId);
                    BindAdminAnalytics(connection);
                }
            }

            if (!IsPostBack && !isAdmin)
            {
                LoadDashboard();
            }
        }

        private void BindUsers(SqlConnection connection, int currentUserId)
        {
            using (SqlCommand command = new SqlCommand(@"SELECT UserID, Username, DisplayName, IsAdmin, IsActive, @CurrentUserID AS CurrentUserID,
                                                               CASE WHEN IsAdmin = 1 THEN 'Admin' ELSE 'User' END AS AccountType,
                                                               CASE WHEN IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS Status
                                                        FROM AppUsers ORDER BY IsAdmin DESC, Username;", connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                command.Parameters.Add("@CurrentUserID", SqlDbType.Int).Value = currentUserId;
                DataTable users = new DataTable();
                adapter.Fill(users);
                UsersGrid.DataSource = users;
                UsersGrid.DataBind();
            }
        }

        private void BindAdminAnalytics(SqlConnection connection)
        {
            using (SqlCommand command = new SqlCommand(@"SELECT COUNT(*) AS TotalUsers,
                                                               ISNULL(SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END), 0) AS ActiveUsers
                                                        FROM AppUsers;", connection))
            using (SqlDataReader reader = command.ExecuteReader(CommandBehavior.SingleRow))
            {
                if (reader.Read())
                {
                    AdminTotalUsersValue.Text = Convert.ToInt32(reader["TotalUsers"], CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                    AdminActiveUsersValue.Text = Convert.ToInt32(reader["ActiveUsers"], CultureInfo.InvariantCulture).ToString("N0", CultureInfo.CurrentCulture);
                }
            }

            const string transactionsSql = @"SELECT TOP 50
                                                '#' + RIGHT('0000' + CONVERT(VARCHAR(10), t.TransactionID), 4) AS FormattedID,
                                                u.DisplayName AS AccountName,
                                                u.Username,
                                                t.TransactionDate,
                                                t.NetAmount,
                                                ISNULL(STUFF((SELECT ', ' + CONVERT(VARCHAR(10), i.QuantitySold) + N'× ' + p.ProductName
                                                              FROM SalesTransactionItems i
                                                              INNER JOIN Products p ON p.ProductID = i.ProductID AND p.UserID = t.UserID
                                                              WHERE i.TransactionID = t.TransactionID
                                                              FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''), 'No items') AS Items
                                            FROM SalesTransactions t
                                            INNER JOIN AppUsers u ON u.UserID = t.UserID
                                            ORDER BY t.TransactionDate DESC, t.TransactionID DESC;";
            using (SqlCommand command = new SqlCommand(transactionsSql, connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                DataTable transactions = new DataTable();
                adapter.Fill(transactions);
                AdminTransactionsGrid.DataSource = transactions;
                AdminTransactionsGrid.DataBind();
            }
        }

        protected void UsersGrid_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow)
            {
                return;
            }

            DataRowView account = (DataRowView)e.Row.DataItem;
            int targetUserId = Convert.ToInt32(account["UserID"], CultureInfo.InvariantCulture);
            int currentUserId = Convert.ToInt32(account["CurrentUserID"], CultureInfo.InvariantCulture);
            bool isAdmin = Convert.ToBoolean(account["IsAdmin"], CultureInfo.InvariantCulture);
            bool isActive = Convert.ToBoolean(account["IsActive"], CultureInfo.InvariantCulture);

            TextBox displayNameTextBox = (TextBox)e.Row.FindControl("EditDisplayNameTextBox");
            Literal adminDisplayName = (Literal)e.Row.FindControl("AdminDisplayName");
            LinkButton saveNameButton = (LinkButton)e.Row.FindControl("SaveDisplayNameButton");
            LinkButton resetPasswordButton = (LinkButton)e.Row.FindControl("SelectResetButton");
            LinkButton toggleActiveButton = (LinkButton)e.Row.FindControl("ToggleActiveButton");

            if (displayNameTextBox != null)
            {
                displayNameTextBox.Text = Convert.ToString(account["DisplayName"], CultureInfo.CurrentCulture);
                displayNameTextBox.Visible = !isAdmin;
            }
            if (adminDisplayName != null)
            {
                adminDisplayName.Text = Convert.ToString(account["DisplayName"], CultureInfo.CurrentCulture);
                adminDisplayName.Visible = isAdmin;
            }
            if (saveNameButton != null)
            {
                saveNameButton.CommandArgument = targetUserId.ToString(CultureInfo.InvariantCulture);
                saveNameButton.Visible = !isAdmin;
            }
            if (resetPasswordButton != null)
            {
                resetPasswordButton.CommandArgument = targetUserId.ToString(CultureInfo.InvariantCulture);
                resetPasswordButton.Visible = !isAdmin;
            }
            if (toggleActiveButton != null)
            {
                toggleActiveButton.CommandArgument = targetUserId.ToString(CultureInfo.InvariantCulture);
                toggleActiveButton.Text = isActive ? "Deactivate" : "Activate";
                toggleActiveButton.Visible = !isAdmin && targetUserId != currentUserId;
            }
        }

        private bool IsCurrentUserAdmin()
        {
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            {
                connection.Open();
                int userId = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                return Login.IsAdministrator(connection, userId);
            }
        }

        protected void CreateAccountButton_Click(object sender, EventArgs e)
        {
            if (!IsCurrentUserAdmin())
            {
                Response.Redirect("~/Dashboard.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            string username = NewAccountUsername.Text.Trim();
            username = username.ToLowerInvariant();
            string displayName = NewAccountDisplayName.Text.Trim();
            string password = NewAccountPassword.Text;
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(displayName) || password.Length < 8)
            {
                ShowUserManagementMessage("Enter a username, display name, and password with at least 8 characters.");
                return;
            }

            try
            {
                using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
                using (SqlCommand command = new SqlCommand(@"INSERT INTO AppUsers (Username, DisplayName, PasswordHash, IsAdmin, IsActive)
                                                             VALUES (@Username, @DisplayName, @PasswordHash, 0, 1);", connection))
                {
                    command.Parameters.Add("@Username", SqlDbType.NVarChar, 50).Value = username;
                    command.Parameters.Add("@DisplayName", SqlDbType.NVarChar, 100).Value = displayName;
                    command.Parameters.Add("@PasswordHash", SqlDbType.NVarChar, 256).Value = Login.HashPassword(password);
                    connection.Open();
                    command.ExecuteNonQuery();
                }

                NewAccountUsername.Text = string.Empty;
                NewAccountDisplayName.Text = string.Empty;
                NewAccountPassword.Text = string.Empty;
                ShowUserManagementMessage("Account created successfully.");
                BindUsersForCurrentAdmin();
            }
            catch (SqlException exception) when (exception.Number == 2601 || exception.Number == 2627)
            {
                ShowUserManagementMessage("That username is already in use.");
            }
            catch (SqlException)
            {
                ShowUserManagementMessage("The account could not be created. Check the database connection and account schema.");
            }
        }

        protected void UsersGrid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (!IsCurrentUserAdmin() || (e.CommandName != "SelectReset" && e.CommandName != "ToggleActive" && e.CommandName != "SaveDisplayName") ||
                !int.TryParse(Convert.ToString(e.CommandArgument, CultureInfo.InvariantCulture), out int targetUserId))
            {
                return;
            }

            int currentUserId;
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            {
                connection.Open();
                currentUserId = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                if (targetUserId == currentUserId && e.CommandName != "SaveDisplayName")
                {
                    ShowUserManagementMessage("You cannot manage your own admin account here.");
                    return;
                }

                if (e.CommandName == "SaveDisplayName")
                {
                    GridViewRow row = ((Control)e.CommandSource).NamingContainer as GridViewRow;
                    TextBox displayNameTextBox = row == null ? null : row.FindControl("EditDisplayNameTextBox") as TextBox;
                    string displayName = displayNameTextBox == null ? string.Empty : displayNameTextBox.Text.Trim();
                    if (string.IsNullOrWhiteSpace(displayName))
                    {
                        ShowUserManagementMessage("Display name cannot be empty.");
                        return;
                    }

                    using (SqlCommand command = new SqlCommand("UPDATE AppUsers SET DisplayName = @DisplayName WHERE UserID = @UserID AND IsAdmin = 0;", connection))
                    {
                        command.Parameters.Add("@DisplayName", SqlDbType.NVarChar, 100).Value = displayName;
                        command.Parameters.Add("@UserID", SqlDbType.Int).Value = targetUserId;
                        ShowUserManagementMessage(command.ExecuteNonQuery() == 0
                            ? "Only regular user display names can be changed here."
                            : "Display name updated.");
                    }
                }
                else if (e.CommandName == "SelectReset")
                {
                    using (SqlCommand command = new SqlCommand("SELECT Username FROM AppUsers WHERE UserID = @UserID AND IsAdmin = 0;", connection))
                    {
                        command.Parameters.Add("@UserID", SqlDbType.Int).Value = targetUserId;
                        object username = command.ExecuteScalar();
                        if (username == null || username == DBNull.Value)
                        {
                            ShowUserManagementMessage("Only regular user accounts can be managed here.");
                            return;
                        }

                        SelectedResetUserID.Value = targetUserId.ToString(CultureInfo.InvariantCulture);
                        ResetPasswordFor.Text = "Reset password for " + Convert.ToString(username, CultureInfo.CurrentCulture);
                        ResetPasswordInput.Text = string.Empty;
                        ResetPasswordPanel.Visible = true;
                    }
                }
                else if (e.CommandName == "ToggleActive")
                {
                    using (SqlCommand command = new SqlCommand(@"UPDATE AppUsers
                                                                 SET IsActive = CASE WHEN IsActive = 1 THEN 0 ELSE 1 END
                                                                 WHERE UserID = @UserID AND IsAdmin = 0 AND UserID <> @CurrentUserID;", connection))
                    {
                        command.Parameters.Add("@UserID", SqlDbType.Int).Value = targetUserId;
                        command.Parameters.Add("@CurrentUserID", SqlDbType.Int).Value = currentUserId;
                        if (command.ExecuteNonQuery() == 0)
                        {
                            ShowUserManagementMessage("Only other regular user accounts can be activated or deactivated.");
                        }
                        else
                        {
                            ShowUserManagementMessage("Account access status updated.");
                        }
                    }
                }
            }

            BindUsersForCurrentAdmin();
        }

        protected void ResetPasswordButton_Click(object sender, EventArgs e)
        {
            if (!IsCurrentUserAdmin() || !int.TryParse(SelectedResetUserID.Value, out int targetUserId))
            {
                return;
            }

            string password = ResetPasswordInput.Text;
            if (password.Length < 8)
            {
                ShowUserManagementMessage("Choose a password with at least 8 characters.");
                ResetPasswordPanel.Visible = true;
                return;
            }

            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            {
                connection.Open();
                int currentUserId = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                using (SqlCommand command = new SqlCommand(@"UPDATE AppUsers SET PasswordHash = @PasswordHash
                                                             WHERE UserID = @UserID AND IsAdmin = 0 AND UserID <> @CurrentUserID;", connection))
                {
                    command.Parameters.Add("@PasswordHash", SqlDbType.NVarChar, 256).Value = Login.HashPassword(password);
                    command.Parameters.Add("@UserID", SqlDbType.Int).Value = targetUserId;
                    command.Parameters.Add("@CurrentUserID", SqlDbType.Int).Value = currentUserId;
                    if (command.ExecuteNonQuery() == 0)
                    {
                        ShowUserManagementMessage("Only another regular user account can have its password reset here.");
                    }
                    else
                    {
                        ShowUserManagementMessage("Password reset successfully.");
                    }
                }
            }

            ResetPasswordPanel.Visible = false;
            BindUsersForCurrentAdmin();
        }

        protected void CancelResetPasswordButton_Click(object sender, EventArgs e)
        {
            ResetPasswordPanel.Visible = false;
            SelectedResetUserID.Value = string.Empty;
        }

        private void BindUsersForCurrentAdmin()
        {
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
            {
                connection.Open();
                int currentUserId = Login.GetCurrentUserId(connection, Context.User.Identity.Name);
                if (Login.IsAdministrator(connection, currentUserId))
                {
                    BindUsers(connection, currentUserId);
                    BindAdminAnalytics(connection);
                }
            }
        }

        private void ShowUserManagementMessage(string message)
        {
            UserManagementMessage.Text = Server.HtmlEncode(message);
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
