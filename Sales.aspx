<%@ Page Title="Sales" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Sales.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Sales" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar">
                    <table class="brand" cellpadding="0" cellspacing="0">
                        <tr>
                            <td><span class="brand-mark">&#127860;</span></td>
                            <td><strong>ENTREP</strong><small>FOOD TRACKER</small></td>
                        </tr>
                    </table>
                    <nav class="tracker-nav">
                        <a href="Dashboard.aspx">Overview</a>
                        <a href="Products.aspx">Products</a>
                        <a class="active" href="Sales.aspx">Sales</a>
                        <a href="Analytics.aspx">Analytics</a>
                    </nav>
                    <div class="target-card">
                        <small>SEMESTER TARGET</small>
                        <strong>&#8369;45,000</strong>
                        <div class="target-bar">
                            <i></i>
                        </div>
                        <span>68% achieved</span>
                    </div>
                    <div class="profile-static">
                        <b>JB</b>
                        <span><strong>Jonas Balante</strong><small>ENTREP Student</small></span>
                    </div>
                </td>
                <td class="tracker-content">
                    <table class="screen-header" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>
                                <h1>Sales</h1>
                                <p>Review transactions and monitor cafeteria sales activity.</p>
                            </td>
                            <td align="right">
                                <span class="record-button">&#65291; &nbsp; Record sale</span>
                            </td>
                        </tr>
                    </table>
                    <table class="summary-grid" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>
                                <div class="summary-card">
                                    <small>Today's sales</small>
                                    <strong>&#8369;2,840</strong>
                                    <span class="positive-change">+12.8% from yesterday</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card">
                                    <small>Transactions</small>
                                    <strong>38</strong>
                                    <span>Today's completed sales</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card">
                                    <small>Average transaction</small>
                                    <strong>&#8369;74.74</strong>
                                    <span>Per transaction</span>
                                </div>
                            </td>
                        </tr>
                    </table>
                    <section class="panel screen-panel">
                        <table class="mock-toolbar" cellpadding="0" cellspacing="0">
                            <tr>
                                <td>
                                    <h2>Recent transactions</h2>
                                    <p>38 transactions recorded today</p>
                                </td>
                                <td align="right">
                                    <span class="static-select">Sep 8–14, 2026 &#8964;</span>
                                    <span class="static-select">All transactions &#8964;</span>
                                </td>
                            </tr>
                        </table>
                        <table class="data-table transaction-list" cellpadding="0" cellspacing="0">
                            <tr>
                                <th>TRANSACTION</th>
                                <th>TIME</th>
                                <th>ITEMS</th>
                                <th>CASHIER</th>
                                <th>PAYMENT</th>
                                <th align="right">TOTAL</th>
                            </tr>
                            <tr>
                                <td><strong>#0214</strong></td>
                                <td>10:42 AM</td>
                                <td>2× Rice Bowl, 1× Iced Milo</td>
                                <td>Jonas B.</td>
                                <td><span class="status-pill paid">Paid</span></td>
                                <td align="right"><strong>&#8369;160</strong></td>
                            </tr>
                            <tr>
                                <td><strong>#0213</strong></td>
                                <td>10:31 AM</td>
                                <td>2× Tuna Sandwich</td>
                                <td>Jonas B.</td>
                                <td><span class="status-pill paid">Paid</span></td>
                                <td align="right"><strong>&#8369;90</strong></td>
                            </tr>
                            <tr>
                                <td><strong>#0212</strong></td>
                                <td>10:18 AM</td>
                                <td>3× Banana Cue</td>
                                <td>Mia R.</td>
                                <td><span class="status-pill paid">Paid</span></td>
                                <td align="right"><strong>&#8369;75</strong></td>
                            </tr>
                            <tr>
                                <td><strong>#0211</strong></td>
                                <td>9:56 AM</td>
                                <td>1× Rice Bowl</td>
                                <td>Jonas B.</td>
                                <td><span class="status-pill paid">Paid</span></td>
                                <td align="right"><strong>&#8369;65</strong></td>
                            </tr>
                            <tr>
                                <td><strong>#0210</strong></td>
                                <td>9:42 AM</td>
                                <td>1× Vegetable Pancit, 1× Iced Milo</td>
                                <td>Mia R.</td>
                                <td><span class="status-pill paid">Paid</span></td>
                                <td align="right"><strong>&#8369;85</strong></td>
                            </tr>
                        </table>
                        <p class="static-note">Showing 5 of 38 transactions</p>
                    </section>
                </td>
            </tr>
        </table>
    </main>
</asp:Content>
