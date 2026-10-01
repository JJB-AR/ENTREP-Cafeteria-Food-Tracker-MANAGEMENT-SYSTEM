<%@ Page Title="Dashboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Dashboard" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard dashboard-page">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar"></td>
                <td class="tracker-content">
                    <header class="screen-header dashboard-page-header">
                        <div>
                            <h1>Good morning, <asp:Literal ID="UserDisplayName" runat="server" /></h1>
                            <p>Here's how your cafeteria products are performing today.</p>
                        </div>
                        <div class="header-actions">
                            <span class="static-select"><asp:Literal ID="DashboardDateRange" runat="server" /></span>
                            <a class="record-button" href="Sales.aspx">&#65291; &nbsp; Record sale</a>
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
                </td>
            </tr>
        </table>
    </main>
</asp:Content>
