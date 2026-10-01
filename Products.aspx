<%@ Page Title="Products" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Products.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Products" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar"></td>
                <td class="tracker-content">
                    <header class="screen-header">
                        <div><h1>Products</h1><p>Review cafeteria products, prices, and stock levels.</p></div>
                    </header>
                    <table class="summary-grid" cellpadding="0" cellspacing="0">
                        <tr>
                            <td><div class="summary-card"><small>Total products</small><strong><asp:Literal ID="TotalProductsValue" runat="server" /></strong><span>Across <asp:Literal ID="CategoryCountValue" runat="server" /> categories</span></div></td>
                            <td><div class="summary-card"><small>Active products</small><strong><asp:Literal ID="ActiveProductsValue" runat="server" /></strong><span>Available for sale</span></div></td>
                            <td><div class="summary-card warning-summary"><small>Low stock</small><strong><asp:Literal ID="LowStockProductsValue" runat="server" /></strong><span>At or below reorder level</span></div></td>
                        </tr>
                    </table>
                    <section class="panel screen-panel">
                        <div class="mock-toolbar"><div><h2>Product catalog</h2><p>Current products and lifetime sales performance</p></div><span class="static-select"><asp:Literal ID="ProductCountText" runat="server" /></span></div>
                        <table class="data-table product-list" cellpadding="0" cellspacing="0">
                            <asp:Repeater ID="ProductRepeater" runat="server">
                                <HeaderTemplate><tr><th>PRODUCT</th><th>PRICE</th><th>IN STOCK</th><th>SOLD</th><th>REVENUE</th><th>STATUS</th></tr></HeaderTemplate>
                                <ItemTemplate>
                                    <tr>
                                        <td><strong><%#: Eval("ProductName") %><small><%#: Eval("CategoryName") %></small></strong></td>
                                        <td>&#8369;<%#: Eval("UnitPrice", "{0:N2}") %></td>
                                        <td><%#: Eval("StockQty") %> servings</td>
                                        <td><%#: Eval("TotalUnitsSold") %></td>
                                        <td><strong>&#8369;<%#: Eval("TotalRevenue", "{0:N2}") %></strong></td>
                                        <td><span class="status-pill <%# Convert.ToInt32(Eval("StockQty")) == 0 ? "unavailable" : (Convert.ToInt32(Eval("StockQty")) <= Convert.ToInt32(Eval("ReorderLevel")) ? "low" : "available") %>"><%# Convert.ToInt32(Eval("StockQty")) == 0 ? "Sold out" : (Convert.ToInt32(Eval("StockQty")) <= Convert.ToInt32(Eval("ReorderLevel")) ? "Low stock" : "Available") %></span></td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </table>
                    </section>
                </td>
            </tr>
        </table>
    </main>
</asp:Content>
