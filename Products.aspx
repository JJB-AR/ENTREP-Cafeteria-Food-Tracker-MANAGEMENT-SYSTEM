<%@ Page Title="Products" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Products.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Products" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar">
                    <table class="brand" cellpadding="0" cellspacing="0">
                        <tr>
                            <td><span class="brand-mark">&#127860;</span></td>
                            <td>
                                <strong>ENTREP</strong>
                                <small>FOOD TRACKER</small>
                            </td>
                        </tr>
                    </table>
                    <nav class="tracker-nav">
                        <a href="Dashboard.aspx">Overview</a>
                        <a class="active" href="Products.aspx">Products</a>
                        <a href="Sales.aspx">Sales</a>
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
                        <span>
                            <strong>Jonas Balante</strong>
                            <small>ENTREP Student</small>
                        </span>
                    </div>
                </td>
                <td class="tracker-content">
                    <table class="screen-header" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>
                                <h1>Products</h1>
                                <p>Manage your cafeteria menu, prices, and stock levels.</p>
                            </td>
                            <td align="right">
                                <span class="record-button">&#65291; &nbsp; Add product</span>
                            </td>
                        </tr>
                    </table>
                    <table class="summary-grid" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>
                                <div class="summary-card">
                                    <small>Total products</small>
                                    <strong>12</strong>
                                    <span>Across 4 categories</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card">
                                    <small>Active products</small>
                                    <strong>10</strong>
                                    <span>Available for sale</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card warning-summary">
                                    <small>Low stock</small>
                                    <strong>2</strong>
                                    <span>Need restocking</span>
                                </div>
                            </td>
                        </tr>
                    </table>
                    <section class="panel screen-panel">
                        <table class="mock-toolbar" cellpadding="0" cellspacing="0">
                            <tr>
                                <td>
                                    <h2>Product catalog</h2>
                                    <p>Product records and sales performance</p>
                                </td>
                                <td align="right">
                                    <span class="static-input">Search products</span> <span class="static-select">All categories &#8964;</span>
                                </td>
                            </tr>
                        </table>
                        <table class="data-table product-list" cellpadding="0" cellspacing="0">
                            <tr>
                                <th>PRODUCT</th>
                                <th>PRICE</th>
                                <th>IN STOCK</th>
                                <th>SOLD</th>
                                <th>REVENUE</th>
                                <th>STATUS</th>
                            </tr>
                            <tr>
                                <td><b class="product-color orange">&#9832;</b><strong>Chicken Rice Bowl<small>Meals</small></strong></td>
                                <td>&#8369;65</td>
                                <td>24 servings</td>
                                <td>128</td>
                                <td><strong>&#8369;8,320</strong></td>
                                <td><span class="status-pill available">Available</span></td>
                            </tr>
                            <tr>
                                <td><b class="product-color blue">&#9832;</b><strong>Tuna Sandwich<small>Snacks</small></strong></td>
                                <td>&#8369;45</td>
                                <td>8 servings</td>
                                <td>96</td>
                                <td><strong>&#8369;4,320</strong></td>
                                <td><span class="status-pill low">Low stock</span></td>
                            </tr>
                            <tr>
                                <td><b class="product-color brown">&#9832;</b><strong>Iced Milo<small>Drinks</small></strong></td>
                                <td>&#8369;30</td>
                                <td>32 cups</td>
                                <td>84</td>
                                <td><strong>&#8369;2,520</strong></td>
                                <td><span class="status-pill available">Available</span></td>
                            </tr>
                            <tr>
                                <td><b class="product-color yellow">&#9832;</b><strong>Banana Cue<small>Snacks</small></strong></td>
                                <td>&#8369;25</td>
                                <td>18 servings</td>
                                <td>72</td>
                                <td><strong>&#8369;1,800</strong></td>
                                <td><span class="status-pill available">Available</span></td>
                            </tr>
                            <tr>
                                <td><b class="product-color green">&#9832;</b><strong>Vegetable Pancit<small>Meals</small></strong></td>
                                <td>&#8369;55</td>
                                <td>0 servings</td>
                                <td>61</td>
                                <td><strong>&#8369;3,355</strong></td>
                                <td><span class="status-pill unavailable">Sold out</span></td>
                            </tr>
                        </table>
                        <p class="static-note">Showing 5 of 12 products</p>
                    </section>
                </td>
            </tr>
        </table>
    </main>
</asp:Content>
