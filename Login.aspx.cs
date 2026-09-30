using System;
using System.Configuration;
using System.Security.Cryptography;
using System.Text;
using System.Web.Security;
using System.Web.UI;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Login : Page
    {
        protected void LoginButton_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
            {
                return;
            }

            string configuredUsername = ConfigurationManager.AppSettings["LoginUsername"];
            string configuredPasswordHash = ConfigurationManager.AppSettings["LoginPasswordHash"];
            string submittedPasswordHash = ComputeSha256(PasswordTextBox.Text);

            if (string.Equals(UsernameTextBox.Text.Trim(), configuredUsername, StringComparison.OrdinalIgnoreCase)
                && string.Equals(submittedPasswordHash, configuredPasswordHash, StringComparison.OrdinalIgnoreCase))
            {
                FormsAuthentication.SetAuthCookie(UsernameTextBox.Text.Trim(), false);
                Response.Redirect("~/Dashboard.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            ErrorMessage.Text = "The username or password is incorrect.";
            ErrorMessage.Visible = true;
        }

        private static string ComputeSha256(string value)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(value));
                return BitConverter.ToString(hash).Replace("-", string.Empty);
            }
        }
    }
}
