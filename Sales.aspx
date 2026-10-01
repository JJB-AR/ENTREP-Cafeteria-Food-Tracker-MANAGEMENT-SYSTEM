<%@ Page Title="Sales" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Sales.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Sales" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar"></td>
                <td class="tracker-content">
                    <header class="screen-header"><div><h1>Sales</h1><p>Review transactions and monitor cafeteria sales activity.</p></div></header>
                    <table class="summary-grid" cellpadding="0" cellspacing="0">
                        <tr>
                            <td><div class="summary-card"><small>Today's sales</small><strong>&#8369;<asp:Literal ID="SalesTotalValue" runat="server" /></strong><span><asp:Literal ID="TodayDateText" runat="server" /></span></div></td>
                            <td><div class="summary-card"><small>Transactions today</small><strong><asp:Literal ID="TodayTransactionCount" runat="server" /></strong><span>Completed sales</span></div></td>
                            <td><div class="summary-card"><small>Average transaction</small><strong>&#8369;<asp:Literal ID="AverageSaleValue" runat="server" /></strong><span>Based on today's sales</span></div></td>
                        </tr>
                    </table>
                    <section class="panel screen-panel">
                        <div class="mock-toolbar"><div><h2>Recent transactions</h2><p><asp:Literal ID="SalesRowsText" runat="server" /></p></div></div>
                        <div class="table-responsive">
                            <table class="data-table transaction-list" cellpadding="0" cellspacing="0">
                                <asp:Repeater ID="SalesRepeater" runat="server">
                                    <HeaderTemplate><tr><th>TRANSACTION</th><th>TIME</th><th>ITEMS</th><th>CASHIER</th><th>PAYMENT</th><th align="right">TOTAL</th></tr></HeaderTemplate>
                                    <ItemTemplate>
                                        <tr>
                                            <td><strong><%#: Eval("FormattedID") %></strong></td>
                                            <td><%#: Eval("TransactionDate", "{0:g}") %></td>
                                            <td><%#: Eval("Items") %></td>
                                            <td><%#: Eval("RecordedBy") %></td>
                                            <td><span class="status-pill paid"><%#: Eval("PaymentMethod") %></span></td>
                                            <td align="right"><strong>&#8369;<%#: Eval("NetAmount", "{0:N2}") %></strong></td>
                                        </tr>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </table>
                        </div>
                    </section>
                </td>
            </tr>
        </table>
    </main>
</asp:Content>
