using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Security.Cryptography;
using System.Web.Security;
using System.Web.UI;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Login : Page
    {
        private const int PasswordIterations = 100000;

        protected void LoginButton_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
            {
                return;
            }

            string displayName;
            try
            {
                if (Authenticate(UsernameTextBox.Text, PasswordTextBox.Text, out displayName))
                {
                    FormsAuthentication.SetAuthCookie(UsernameTextBox.Text.Trim(), false);
                    Response.Redirect("~/Dashboard.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }
            catch (SqlException)
            {
                ShowMessage("Unable to connect to the account database. Run sql/CafeteriaFoodTracker.sql and try again.");
                return;
            }

            ShowMessage("The username or password is incorrect.");
        }

        protected void ShowSignUpButton_Click(object sender, EventArgs e)
        {
            LoginPanel.Visible = false;
            SignUpPanel.Visible = true;
            ErrorMessage.Visible = false;
        }

        protected void ReturnToLoginButton_Click(object sender, EventArgs e)
        {
            LoginPanel.Visible = true;
            SignUpPanel.Visible = false;
            ErrorMessage.Visible = false;
        }

        protected void SignUpButton_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
            {
                LoginPanel.Visible = false;
                SignUpPanel.Visible = true;
                return;
            }

            string username = NewUsernameTextBox.Text.Trim();
            string password = NewPasswordTextBox.Text;
            if (password.Length < 8)
            {
                LoginPanel.Visible = false;
                SignUpPanel.Visible = true;
                ShowMessage("Choose a password with at least 8 characters.");
                return;
            }

            try
            {
                if (!Register(username, DisplayNameTextBox.Text, password))
                {
                    LoginPanel.Visible = false;
                    SignUpPanel.Visible = true;
                    ShowMessage("That username is already in use.");
                    return;
                }

                FormsAuthentication.SetAuthCookie(username, false);
                Response.Redirect("~/Dashboard.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch (SqlException)
            {
                LoginPanel.Visible = false;
                SignUpPanel.Visible = true;
                ShowMessage("Unable to connect to the account database. Run sql/CafeteriaFoodTracker.sql and try again.");
            }
        }

        private static bool Register(string username, string displayName, string password)
        {
            const string sql = @"INSERT INTO AppUsers (Username, DisplayName, PasswordHash)
                                 VALUES (@Username, @DisplayName, @PasswordHash);";
            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.Add("@Username", SqlDbType.NVarChar, 50).Value = username;
                command.Parameters.Add("@DisplayName", SqlDbType.NVarChar, 100).Value = displayName.Trim();
                command.Parameters.Add("@PasswordHash", SqlDbType.NVarChar, 256).Value = HashPassword(password);
                connection.Open();
                try
                {
                    command.ExecuteNonQuery();
                    return true;
                }
                catch (SqlException exception) when (exception.Number == 2601 || exception.Number == 2627)
                {
                    return false;
                }
            }

        }

        private static bool Authenticate(string username, string password, out string displayName)
        {
            const string sql = @"SELECT DisplayName, PasswordHash
                                 FROM AppUsers
                                 WHERE Username = @Username AND IsActive = 1;";
            displayName = null;
            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.Add("@Username", SqlDbType.NVarChar, 50).Value = username.Trim();
                connection.Open();
                using (SqlDataReader reader = command.ExecuteReader(CommandBehavior.SingleRow))
                {
                    if (!reader.Read() || !VerifyPassword(password, reader.GetString(1)))
                    {
                        return false;
                    }

                    displayName = reader.GetString(0);
                    return true;
                }
            }
        }

        internal static int GetCurrentUserId(SqlConnection connection, string username)
        {
            if (connection == null || connection.State != ConnectionState.Open)
            {
                throw new InvalidOperationException("An open database connection is required.");
            }

            using (SqlCommand command = new SqlCommand("SELECT UserID FROM AppUsers WHERE Username = @Username AND IsActive = 1;", connection))
            {
                command.Parameters.Add("@Username", SqlDbType.NVarChar, 50).Value = username ?? string.Empty;
                object result = command.ExecuteScalar();
                if (result == null || result == DBNull.Value)
                {
                    throw new InvalidOperationException("The signed-in account is not active.");
                }

                return Convert.ToInt32(result, CultureInfo.InvariantCulture);
            }
        }

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

        private static string HashPassword(string password)
        {
            byte[] salt = new byte[16];
            using (RandomNumberGenerator generator = RandomNumberGenerator.Create())
            {
                generator.GetBytes(salt);
            }

            byte[] hash;
            using (Rfc2898DeriveBytes deriveBytes = new Rfc2898DeriveBytes(password, salt, PasswordIterations))
            {
                hash = deriveBytes.GetBytes(32);
            }

            return PasswordIterations.ToString(CultureInfo.InvariantCulture) + "." +
                   Convert.ToBase64String(salt) + "." + Convert.ToBase64String(hash);
        }

        private static bool VerifyPassword(string password, string storedHash)
        {
            string[] parts = storedHash.Split('.');
            int iterations;
            if (parts.Length != 3 || !int.TryParse(parts[0], NumberStyles.None, CultureInfo.InvariantCulture, out iterations) || iterations < 1)
            {
                return false;
            }

            byte[] salt;
            byte[] expectedHash;
            try
            {
                salt = Convert.FromBase64String(parts[1]);
                expectedHash = Convert.FromBase64String(parts[2]);
            }
            catch (FormatException)
            {
                return false;
            }

            byte[] actualHash;
            using (Rfc2898DeriveBytes deriveBytes = new Rfc2898DeriveBytes(password, salt, iterations))
            {
                actualHash = deriveBytes.GetBytes(expectedHash.Length);
            }

            int difference = actualHash.Length ^ expectedHash.Length;
            for (int index = 0; index < actualHash.Length && index < expectedHash.Length; index++)
            {
                difference |= actualHash[index] ^ expectedHash[index];
            }

            return difference == 0;
        }

        private void ShowMessage(string message)
        {
            ErrorMessage.Text = message;
            ErrorMessage.Visible = true;
        }
    }
}
