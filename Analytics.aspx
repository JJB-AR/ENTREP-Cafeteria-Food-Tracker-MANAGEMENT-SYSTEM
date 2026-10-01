<%@ Page Title="Analytics" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Analytics.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Analytics" %>

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
                        <a href="Sales.aspx">Sales</a>
                        <a class="active" href="Analytics.aspx">Analytics</a>
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
                                <h1>Analytics</h1>
                                <p>Understand sales patterns and see which products perform best.</p>
                            </td>
                            <td align="right">
                                <span class="static-select">Sep 8&#8729;14, 2026 &#8964;</span>
                            </td>
                        </tr>
                    </table>
                    <table class="summary-grid" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>
                                <div class="summary-card">
                                    <small>Total revenue</small>
                                    <strong>&#8369;12,840</strong>
                                    <span class="positive-change">+18.2% from last week</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card">
                                    <small>Items sold</small>
                                    <strong>486</strong>
                                    <span class="positive-change">+12.5% from last week</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card">
                                    <small>Best seller</small>
                                    <strong class="summary-product">Chicken Rice Bowl</strong>
                                    <span>128 servings sold</span>
                                </div>
                            </td>
                        </tr>
                    </table>
                    <table class="analytics-layout" cellpadding="0" cellspacing="0">
                        <tr>
                            <td class="panel analytics-trend">
                                <table class="mock-toolbar" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td>
                                            <h2>Sales trend</h2>
                                            <p>Daily revenue for the selected week</p>
                                        </td>
                                        <td align="right">
                                            <span class="legend">
                                                <i></i>Revenue
                                            </span>
                                        </td>
                                    </tr>
                                </table>
                                <table class="analytics-chart" cellpadding="0" cellspacing="0">
                                    <tr class="analytics-bars">
                                        <td><i style="height:54px"></i></td>
                                        <td><i style="height:70px"></i></td>
                                        <td><i style="height:61px"></i></td>
                                        <td><i style="height:91px"></i></td>
                                        <td><i style="height:80px"></i></td>
                                        <td><i class="highlight" style="height:114px"></i></td>
                                        <td><i style="height:109px"></i></td>
                                    </tr>
                                    <tr class="analytics-labels">
                                        <td>Mon</td>
                                        <td>Tue</td>
                                        <td>Wed</td>
                                        <td>Thu</td>
                                        <td>Fri</td>
                                        <td>Sat</td>
                                        <td>Sun</td>
                                    </tr>
                                </table>
                            </td>
                            <td class="panel performance-panel">
                                <table class="mock-toolbar" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td>
                                            <h2>Top products</h2>
                                            <p>By revenue this week</p>
                                        </td>
                                    </tr>
                                </table>
                                <table class="ranking-table" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td><b class="rank-number">1</b></td>
                                        <td><strong>Chicken Rice Bowl<small>128 sold</small></strong></td>
                                        <td align="right"><strong>&#8369;8,320</strong><small class="positive-change">+24%</small></td>
                                    </tr>
                                    <tr>
                                        <td><b class="rank-number">2</b></td>
                                        <td><strong>Tuna Sandwich<small>96 sold</small></strong></td>
                                        <td align="right"><strong>&#8369;4,320</strong><small class="positive-change">+18%</small></td>
                                    </tr>
                                    <tr>
                                        <td><b class="rank-number">3</b></td>
                                        <td><strong>Iced Milo<small>84 sold</small></strong></td>
                                        <td align="right"><strong>&#8369;2,520</strong><small class="positive-change">+9%</small></td>
                                    </tr>
                                    <tr>
                                        <td><b class="rank-number">4</b></td>
                                        <td><strong>Banana Cue<small>72 sold</small></strong></td>
                                        <td align="right"><strong>&#8369;1,800</strong><small class="negative-change">−3%</small></td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </table>
                    <section class="panel insight-panel">
                        <h2>Sales insights</h2>
                        <table class="insight-grid" cellpadding="0" cellspacing="0">
                            <tr>
                                <td><b class="insight-icon mint">&#8599;</b><strong>Best sales day</strong><span>Saturday generated the most revenue at &#8369;2,300.</span></td>
                                <td><b class="insight-icon peach">&#9733;</b><strong>Top performer</strong><span>Chicken Rice Bowl leads with 128 servings sold.</span></td>
                                <td><b class="insight-icon lavender">&#8594;</b><strong>Sales frequency</strong><span>38 transactions were recorded today.</span></td>
                            </tr>
                        </table>
                    </section>
                </td>
            </tr>
        </table>
    </main>
</asp:Content>