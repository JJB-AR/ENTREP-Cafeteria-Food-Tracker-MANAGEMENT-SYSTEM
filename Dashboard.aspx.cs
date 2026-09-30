using System;
using System.Web.Security;
using System.Web.UI;

namespace ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM
{
    public partial class Dashboard : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                UsernameLabel.Text = Context.User.Identity.Name;
            }
        }

        protected void LogoutButton_Click(object sender, EventArgs e)
        {
            FormsAuthentication.SignOut();
            Response.Redirect("~/Login.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
    }
}
