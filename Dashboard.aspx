<%@ Page Title="Dashboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Dashboard" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main id="DashboardLayout" runat="server" class="tracker-dashboard dashboard-page">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar"></td>
                <td class="tracker-content">
                    <asp:Panel ID="AdminManagementPanel" runat="server" CssClass="admin-management" Visible="false">
                        <header class="screen-header dashboard-page-header">
                            <div>
                                <h1>Manage users</h1>
                                <p>Create accounts, reset passwords, and manage access.</p>
                            </div>
                        </header>
                        <section class="admin-user-metrics" aria-label="User account summary">
                            <article class="panel admin-user-metric"><span>Total users</span><strong><asp:Literal ID="AdminTotalUsersValue" runat="server" /></strong></article>
                            <article class="panel admin-user-metric"><span>Active users</span><strong><asp:Literal ID="AdminActiveUsersValue" runat="server" /></strong></article>
                        </section>
                        <section class="panel user-management-panel admin-transactions-panel">
                            <div class="panel-heading"><div><h2>Recent transactions</h2><p>Showing the account that owns each transaction.</p></div></div>
                            <div class="user-table-scroll">
                                <asp:GridView ID="AdminTransactionsGrid" runat="server" AutoGenerateColumns="false" CssClass="user-management-grid admin-transactions-grid" GridLines="None" EmptyDataText="No transactions have been recorded yet.">
                                    <Columns>
                                        <asp:BoundField DataField="FormattedID" HeaderText="Transaction" />
                                        <asp:BoundField DataField="AccountName" HeaderText="Account" />
                                        <asp:BoundField DataField="Username" HeaderText="Username" />
                                        <asp:BoundField DataField="TransactionDate" HeaderText="Date and time" DataFormatString="{0:MMM d, yyyy h:mm tt}" />
                                        <asp:BoundField DataField="Items" HeaderText="Items" />
                                        <asp:BoundField DataField="NetAmount" HeaderText="Amount" DataFormatString="₱{0:N2}" />
                                    </Columns>
                                </asp:GridView>
                            </div>
                        </section>
                        <section class="panel user-management-panel create-user-panel">
                            <div class="panel-heading"><div><h2>Create account</h2><p>New accounts are regular users, not administrators.</p></div></div>
                            <div class="user-management-form">
                                <div class="user-form-field"><asp:Label ID="NewAccountUsernameLabel" runat="server" AssociatedControlID="NewAccountUsername">Username</asp:Label><asp:TextBox ID="NewAccountUsername" runat="server" CssClass="login-input" MaxLength="50" placeholder="Enter username" /></div>
                                <div class="user-form-field"><asp:Label ID="NewAccountDisplayNameLabel" runat="server" AssociatedControlID="NewAccountDisplayName">Display name</asp:Label><asp:TextBox ID="NewAccountDisplayName" runat="server" CssClass="login-input" MaxLength="100" placeholder="Enter display name" /></div>
                                <div class="user-form-field"><asp:Label ID="NewAccountPasswordLabel" runat="server" AssociatedControlID="NewAccountPassword">Temporary password</asp:Label><asp:TextBox ID="NewAccountPassword" runat="server" CssClass="login-input" TextMode="Password" MaxLength="100" placeholder="At least 8 characters" /></div>
                                <asp:Button ID="CreateAccountButton" runat="server" Text="Create user" CssClass="login-submit" OnClick="CreateAccountButton_Click" />
                            </div>
                        </section>
                        <section class="panel user-management-panel">
                            <div class="panel-heading"><div><h2>Accounts</h2><p>Admin accounts and your own account cannot be deactivated here.</p></div></div>
                            <asp:Label ID="UserManagementMessage" runat="server" CssClass="login-hint" EnableViewState="false" />
                            <div class="user-table-scroll">
                            <asp:GridView ID="UsersGrid" runat="server" AutoGenerateColumns="false" DataKeyNames="UserID" CssClass="user-management-grid" GridLines="None" OnRowCommand="UsersGrid_RowCommand" OnRowDataBound="UsersGrid_RowDataBound">
                                <Columns>
                                    <asp:BoundField DataField="Username" HeaderText="Username" />
                                    <asp:TemplateField HeaderText="Display name">
                                        <ItemTemplate>
                                            <asp:TextBox ID="EditDisplayNameTextBox" runat="server" CssClass="user-display-name-input" MaxLength="100" />
                                            <asp:Literal ID="AdminDisplayName" runat="server" Mode="Encode" />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:BoundField DataField="AccountType" HeaderText="Role" />
                                    <asp:BoundField DataField="Status" HeaderText="Status" />
                                    <asp:TemplateField HeaderText="Actions">
                                        <ItemTemplate>
                                            <div class="user-actions">
                                            <asp:LinkButton ID="SaveDisplayNameButton" runat="server" Text="Save name" CommandName="SaveDisplayName" CausesValidation="false" />
                                            <asp:LinkButton ID="SelectResetButton" runat="server" Text="Reset password" CommandName="SelectReset" CausesValidation="false" />
                                            <asp:LinkButton ID="ToggleActiveButton" runat="server" CommandName="ToggleActive" CausesValidation="false" OnClientClick="return confirm('Change this account access status?');" />
                                            </div>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                            </div>
                            <asp:Panel ID="ResetPasswordPanel" runat="server" CssClass="user-management-form" Visible="false">
                                <asp:HiddenField ID="SelectedResetUserID" runat="server" />
                                <asp:Label ID="ResetPasswordFor" runat="server" AssociatedControlID="ResetPasswordInput" />
                                <asp:TextBox ID="ResetPasswordInput" runat="server" CssClass="login-input" TextMode="Password" MaxLength="100" placeholder="New password (8+ characters)" />
                                <asp:Button ID="ResetPasswordButton" runat="server" Text="Set password" CssClass="login-submit" OnClick="ResetPasswordButton_Click" />
                                <asp:Button ID="CancelResetPasswordButton" runat="server" Text="Cancel" CssClass="login-signup-link" CausesValidation="false" OnClick="CancelResetPasswordButton_Click" />
                            </asp:Panel>
                        </section>
                    </asp:Panel>
                    <asp:Panel ID="SalesDashboardPanel" runat="server">
                    <header class="screen-header dashboard-page-header">
                        <div>
                            <h1>Good morning, <asp:Literal ID="UserDisplayName" runat="server" /></h1>
                            <p>Here's how your cafeteria products are performing today.</p>
                        </div>
                        <div class="header-actions">
                            <span class="static-select"><asp:Literal ID="DashboardDateRange" runat="server" /></span>
                            <a class="record-button" href="Sales.aspx?action=new">&#65291; &nbsp; Record sale</a>
                        </div>
                    </header>
                    <div class="dashboard-grid">
                        <section class="metric-stack" aria-label="Today's sales summary">
                            <div class="metric-card"><span class="metric-icon mint">&#8369;</span><span><small>Total sales</small><strong>&#8369;<asp:Literal ID="TotalSalesValue" runat="server" /></strong></span></div>
                            <div class="metric-card"><span class="metric-icon peach">&#9633;</span><span><small>Items sold</small><strong><asp:Literal ID="ItemsSoldValue" runat="server" /></strong></span></div>
                            <div class="metric-card"><span class="metric-icon lavender">&#9641;</span><span><small>Transactions</small><strong><asp:Literal ID="TransactionsValue" runat="server" /></strong></span></div>
                        </section>
                        <section class="panel trend-panel">
                            <div class="panel-heading"><div><h2>Sales trend</h2><p>Revenue over the last 7 days</p></div><span class="legend">&#9679; Daily revenue</span></div>
                            <div class="daily-chart" role="img" aria-label="Daily revenue for the last seven days">
                                <asp:Repeater ID="DailySalesRepeater" runat="server">
                                    <ItemTemplate><div class="chart-column"><i class='<%# Convert.ToBoolean(Eval("IsToday")) ? "highlight" : String.Empty %>' style='height:<%# Eval("BarHeight") %>px' title='&#8369;<%# Eval("Revenue", "{0:N2}") %>'></i><span><%#: Eval("DayLabel") %></span></div></ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </section>
                    </div>
                    <div class="lower-grid">
                        <section class="panel product-panel">
                            <div class="panel-heading"><div><h2>Product performance</h2><p>Track quantity sold, revenue and sales frequency</p></div><a class="add-button" href="Products.aspx">&#65291; &nbsp; View products</a></div>
                            <div class="dashboard-product-table">
                                <div class="dashboard-product-head"><span>PRODUCT</span><span>PRICE</span><span>SOLD</span><span>REVENUE</span><span>ORDERS</span></div>
                                <asp:Repeater ID="ProductPerformanceRepeater" runat="server">
                                    <ItemTemplate><div class="dashboard-product-row"><span class="product-color"><%#: Eval("ProductName").ToString().Substring(0, 1) %></span><strong><%#: Eval("ProductName") %><small><%#: Eval("CategoryName") %></small></strong><span>&#8369;<%#: Eval("UnitPrice", "{0:N2}") %></span><span><%#: Eval("TotalUnitsSold") %></span><strong>&#8369;<%#: Eval("TotalRevenue", "{0:N2}") %></strong><span><%#: Eval("TimesOrdered") %></span></div></ItemTemplate>
                                </asp:Repeater>
                            </div>
                            <a class="panel-link" href="Products.aspx">View all products</a>
                        </section>
                        <section class="panel sales-panel">
                            <div class="panel-heading"><div><h2>Recent sales</h2><p>Today · <asp:Literal ID="TodayTransactionCount" runat="server" /> transactions</p></div><a class="filter-button" href="Sales.aspx" aria-label="View sales">&#9776;</a></div>
                            <div class="dashboard-sales-list">
                                <asp:Repeater ID="RecentSalesRepeater" runat="server">
                                    <ItemTemplate><div class="dashboard-sale-row"><b>&#8369;</b><span><strong><%#: Eval("FormattedID") %></strong><small><%#: Eval("Items") %></small></span><time><%#: Eval("TransactionDate", "{0:h:mm tt}") %></time><strong>&#8369;<%#: Eval("NetAmount", "{0:N2}") %></strong></div></ItemTemplate>
                                </asp:Repeater>
                            </div>
                            <asp:Panel ID="LowStockPanel" runat="server" CssClass="low-stock" Visible="false"><span>&#9888;</span><span><strong>Low stock alert</strong><small><asp:Literal ID="LowStockMessage" runat="server" /></small></span><a href="Products.aspx">Update</a></asp:Panel>
                            <a class="panel-link" href="Sales.aspx">View all transactions</a>
                        </section>
                    </div>
                    </asp:Panel>
                </td>
            </tr>
        </table>
    </main>
</asp:Content>
