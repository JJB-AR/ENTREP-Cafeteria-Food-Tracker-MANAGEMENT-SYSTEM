using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Optimization;
using System.Web.Routing;
using System.Web.Security;
using System.Web.SessionState;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public class Global : HttpApplication
    {
        void Application_Start(object sender, EventArgs e)
        {
            // Code that runs on application startup
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }

        void Application_PostAuthenticateRequest(object sender, EventArgs e)
        {
            if (Context.User == null || !Context.User.Identity.IsAuthenticated)
            {
                return;
            }

            try
            {
                using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["CafeteriaFoodTrackerDB"].ConnectionString))
                using (SqlCommand command = new SqlCommand("SELECT COUNT(*) FROM AppUsers WHERE LOWER(Username) = @Username AND IsActive = 1;", connection))
                {
                    command.Parameters.Add("@Username", SqlDbType.NVarChar, 50).Value = Context.User.Identity.Name.Trim().ToLowerInvariant();
                    connection.Open();
                    int activeAccountCount = Convert.ToInt32(command.ExecuteScalar());
                    if (activeAccountCount == 0)
                    {
                        FormsAuthentication.SignOut();
                        Context.Response.Redirect("~/Login.aspx", false);
                        Context.ApplicationInstance.CompleteRequest();
                    }
                }
            }
            catch (SqlException)
            {
            }
        }
    }
}