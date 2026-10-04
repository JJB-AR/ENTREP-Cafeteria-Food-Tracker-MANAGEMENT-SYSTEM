using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.UI.HtmlControls;
using System.Web.Security;
using System.Web.UI;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            string pageName = System.IO.Path.GetFileNameWithoutExtension(Page.AppRelativeVirtualPath);
            bool isLoginPage = String.Equals(pageName, "Login", StringComparison.OrdinalIgnoreCase);
            bool isDefaultPage = String.Equals(pageName, "Default", StringComparison.OrdinalIgnoreCase);
            bool isAuthenticated = Context.User.Identity.IsAuthenticated;

            AccountToolbar.Visible = isAuthenticated && !isLoginPage;
            TrackerSidebar.Visible = false;

            if (isDefaultPage)
            {
                Response.Redirect(isAuthenticated ? "~/Dashboard.aspx" : "~/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            if (isLoginPage && isAuthenticated)
            {
                Response.Redirect("~/Dashboard.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            if (!isAuthenticated && !isLoginPage)
            {
                Response.Redirect("~/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            if (AccountToolbar.Visible)
            {
                using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
                using (SqlCommand command = new SqlCommand("SELECT DisplayName, IsAdmin FROM AppUsers WHERE Username = @Username AND IsActive = 1", connection))
                {
                    command.Parameters.AddWithValue("@Username", Context.User.Identity.Name);
                    connection.Open();
                    string displayName;
                    bool isAdmin = false;
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            displayName = Convert.ToString(reader["DisplayName"]);
                            isAdmin = Convert.ToBoolean(reader["IsAdmin"]);
                        }
                        else
                        {
                            displayName = Context.User.Identity.Name;
                        }
                    }
                    if (string.IsNullOrWhiteSpace(displayName))
                    {
                        displayName = Context.User.Identity.Name;
                    }

                    TrackerSidebar.Visible = AccountToolbar.Visible && !isAdmin;

                    AuthenticatedUserName.Text = Server.HtmlEncode(displayName);
                    SidebarUserName.Text = Server.HtmlEncode(displayName);
                    UserInitials.Text = Server.HtmlEncode(GetInitials(displayName));
                }

                SetActiveNavigationLink(pageName);
            }
        }

        protected void LogoutButton_Click(object sender, EventArgs e)
        {
            FormsAuthentication.SignOut();
            Session.Clear();
            Response.Redirect("~/Login.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }

        private void SetActiveNavigationLink(string pageName)
        {
            HtmlAnchor activeLink = null;
            switch (pageName)
            {
                case "Dashboard": activeLink = OverviewLink; break;
                case "Products": activeLink = ProductsLink; break;
                case "Sales": activeLink = SalesLink; break;
                case "Analytics": activeLink = AnalyticsLink; break;
            }

            if (activeLink != null)
            {
                activeLink.Attributes["class"] = "active";
                activeLink.Attributes["aria-current"] = "page";
            }
        }

        private static string GetInitials(string name)
        {
            string[] parts = name.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 0)
            {
                return "?";
            }

            return parts.Length == 1
                ? parts[0].Substring(0, 1).ToUpperInvariant()
                : (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpperInvariant();
        }
    }
}