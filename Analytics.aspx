<%@ Page Title="Analytics" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Analytics.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Analytics" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard analytics-page">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar"></td>
                <td class="tracker-content">
                    <header class="screen-header"><div><h1>Analytics</h1><p>Understand sales patterns and see which products perform best.</p></div><span class="static-select"><asp:Literal ID="DateRangeText" runat="server" /></span></header>
                    <div class="analytics-summary">
                        <div class="summary-card"><small>Revenue, last 7 days</small><strong>&#8369;<asp:Literal ID="TotalRevenueValue" runat="server" /></strong><span><asp:Literal ID="WeeklyTransactionCount" runat="server" /> transactions</span></div>
                        <div class="summary-card"><small>Items sold, last 7 days</small><strong><asp:Literal ID="ItemsSoldValue" runat="server" /></strong><span>Across all products</span></div>
                        <div class="summary-card"><small>Best seller</small><strong class="summary-product"><asp:Literal ID="BestSellerName" runat="server" /></strong><span><asp:Literal ID="BestSellerUnits" runat="server" /> units sold this week</span></div>
                    </div>
                    <div class="analytics-layout">
                        <section class="panel analytics-trend">
                            <div class="panel-heading"><div><h2>Sales trend</h2><p>Daily revenue for the selected week</p></div><span class="legend">&#9679; Revenue</span></div>
                            <div class="daily-chart" role="img" aria-label="Daily revenue for the last seven days">
                                <asp:Repeater ID="DailySalesRepeater" runat="server">
                                    <ItemTemplate><div class="chart-column"><i class='<%# Convert.ToBoolean(Eval("IsToday")) ? "highlight" : String.Empty %>' style='height:<%# Eval("BarHeight") %>px' title='&#8369;<%# Eval("Revenue", "{0:N2}") %>'></i><span><%#: Eval("DayLabel") %></span></div></ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </section>
                        <section class="panel performance-panel">
                            <div class="panel-heading"><div><h2>Top products</h2><p>By revenue this week</p></div></div>
                            <div class="ranking-list">
                                <asp:Repeater ID="TopProductsRepeater" runat="server">
                                    <ItemTemplate><div class="ranking-row"><b class="rank-number"><%# Container.ItemIndex + 1 %></b><strong><%#: Eval("ProductName") %><small><%#: Eval("UnitsSold") %> sold</small></strong><span><strong>&#8369;<%#: Eval("Revenue", "{0:N2}") %></strong></span></div></ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </section>
                    </div>
                    <section class="panel insight-panel">
                        <h2>Sales insights</h2>
                        <div class="insight-grid">
                            <div><b class="insight-icon mint">&#8599;</b><strong>Best sales day</strong><span><asp:Literal ID="BestSalesDayText" runat="server" /></span></div>
                            <div><b class="insight-icon peach">&#9733;</b><strong>Top performer</strong><span><asp:Literal ID="TopPerformerText" runat="server" /></span></div>
                            <div><b class="insight-icon lavender">&#8594;</b><strong>Today's activity</strong><span><asp:Literal ID="TodayActivityText" runat="server" /></span></div>
                        </div>
                    </section>
                </td>
            </tr>
        </table>
    </main>
</asp:Content>