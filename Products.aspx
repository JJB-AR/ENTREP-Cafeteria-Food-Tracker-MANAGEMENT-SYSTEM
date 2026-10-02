<%@ Page Title="Products" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Products.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Products" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar"></td>
                <td class="tracker-content">
                    <header class="screen-header">
                        <div>
                            <h1>Products</h1>
                            <p>Review and manage cafeteria products, prices, and inventory stock in SQL.</p>
                        </div>
                        <div class="header-actions">
                            <asp:Button ID="BtnOpenAddProduct" runat="server" Text="&#65291; &nbsp; Add Product" CssClass="record-button" OnClick="BtnOpenAddProduct_Click" CausesValidation="false" />
                        </div>
                    </header>

                    <asp:Panel ID="AlertPanel" runat="server" Visible="false" CssClass="alert-banner alert-success">
                        <span><asp:Literal ID="AlertMessage" runat="server" /></span>
                        <asp:LinkButton ID="btnDismissAlert" runat="server" OnClick="BtnDismissAlert_Click" CausesValidation="false" aria-label="Close notification">&times;</asp:LinkButton>
                    </asp:Panel>

                    <table class="summary-grid" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>
                                <div class="summary-card">
                                    <small>Total products</small>
                                    <strong><asp:Literal ID="TotalProductsValue" runat="server" /></strong>
                                    <span>Across <asp:Literal ID="CategoryCountValue" runat="server" /> categories</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card">
                                    <small>Active products</small>
                                    <strong><asp:Literal ID="ActiveProductsValue" runat="server" /></strong>
                                    <span>Available for sale</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card warning-summary">
                                    <small>Low stock</small>
                                    <strong><asp:Literal ID="LowStockProductsValue" runat="server" /></strong>
                                    <span>At or below reorder level</span>
                                </div>
                            </td>
                        </tr>
                    </table>

                    <section class="panel screen-panel">
                        <div class="filter-toolbar">
                            <div>
                                <h2>Product catalog</h2>
                                <p>Live SQL inventory and lifetime sales performance</p>
                            </div>
                            <div class="filter-group">
                                <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control-input" style="width:170px;" placeholder="Search name or category..." AutoPostBack="true" OnTextChanged="FilterChanged" />
                                <asp:DropDownList ID="ddlCategoryFilter" runat="server" CssClass="static-select" AutoPostBack="true" OnSelectedIndexChanged="FilterChanged" />
                                <asp:DropDownList ID="ddlStockFilter" runat="server" CssClass="static-select" AutoPostBack="true" OnSelectedIndexChanged="FilterChanged">
                                    <asp:ListItem Text="All stock levels" Value="" />
                                    <asp:ListItem Text="In stock" Value="InStock" />
                                    <asp:ListItem Text="Low stock" Value="LowStock" />
                                    <asp:ListItem Text="Sold out" Value="SoldOut" />
                                </asp:DropDownList>
                                <span class="static-select"><asp:Literal ID="ProductCountText" runat="server" /></span>
                            </div>
                        </div>

                        <div class="table-responsive">
                            <table class="data-table product-list" cellpadding="0" cellspacing="0">
                                <asp:Repeater ID="ProductRepeater" runat="server" OnItemCommand="ProductRepeater_ItemCommand">
                                    <HeaderTemplate>
                                        <tr>
                                            <th>PRODUCT</th>
                                            <th>PRICE</th>
                                            <th>COST</th>
                                            <th>IN STOCK</th>
                                            <th>SOLD</th>
                                            <th>REVENUE</th>
                                            <th>STATUS</th>
                                            <th style="width:115px;text-align:right;">ACTIONS</th>
                                        </tr>
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <tr>
                                            <td>
                                                <strong><%#: Eval("ProductName") %></strong>
                                                <small><%#: Eval("CategoryName") %><%# string.IsNullOrWhiteSpace(Eval("Description") as string) ? "" : " &#183; " + Server.HtmlEncode(Eval("Description").ToString()) %></small>
                                            </td>
                                            <td>&#8369;<%#: Eval("UnitPrice", "{0:N2}") %></td>
                                            <td>&#8369;<%#: Eval("CostPrice", "{0:N2}") %></td>
                                            <td><%#: Eval("StockQty") %> servings</td>
                                            <td><%#: Eval("TotalUnitsSold") %></td>
                                            <td><strong>&#8369;<%#: Eval("TotalRevenue", "{0:N2}") %></strong></td>
                                            <td>
                                                <span class="status-pill <%# Convert.ToInt32(Eval("StockQty")) == 0 ? "unavailable" : (Convert.ToInt32(Eval("StockQty")) <= Convert.ToInt32(Eval("ReorderLevel")) ? "low" : "available") %>">
                                                    <%# Convert.ToInt32(Eval("StockQty")) == 0 ? "Sold out" : (Convert.ToInt32(Eval("StockQty")) <= Convert.ToInt32(Eval("ReorderLevel")) ? "Low stock" : "Available") %>
                                                </span>
                                            </td>
                                            <td style="text-align:right;white-space:nowrap;">
                                                <asp:LinkButton ID="btnEdit" runat="server" CommandName="EditProduct" CommandArgument='<%# Eval("ProductID") %>' CssClass="table-action-btn edit-btn" CausesValidation="false">Edit</asp:LinkButton>
                                                <asp:LinkButton ID="btnDelete" runat="server" CommandName="DeleteProduct" CommandArgument='<%# Eval("ProductID") %>' CssClass="table-action-btn toggle-btn" CausesValidation="false" OnClientClick="return confirm('Are you sure you want to remove/deactivate this product?');">Deactivate</asp:LinkButton>
                                            </td>
                                        </tr>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </table>
                        </div>

                        <asp:Panel ID="EmptyProductsPanel" runat="server" Visible="false" CssClass="empty-data-state">
                            <p>No products found matching the current search and filter criteria.</p>
                        </asp:Panel>
                    </section>
                </td>
            </tr>
        </table>
    </main>

    <!-- Add / Edit Product Modal -->
    <asp:Panel ID="ProductModal" runat="server" CssClass="tracker-modal-overlay" Visible="false">
        <div class="tracker-modal-card" role="dialog" aria-modal="true" aria-labelledby="modalHeading">
            <div class="tracker-modal-header">
                <div>
                    <h2 id="modalHeading"><asp:Literal ID="ModalTitle" runat="server" Text="Add New Product" /></h2>
                    <p>Product records and pricing are saved directly to Microsoft SQL Server.</p>
                </div>
                <asp:LinkButton ID="btnCloseModal" runat="server" CssClass="modal-close-btn" OnClick="BtnCloseModal_Click" CausesValidation="false" aria-label="Close dialog">&times;</asp:LinkButton>
            </div>
            <div class="tracker-modal-body">
                <asp:HiddenField ID="hfProductID" runat="server" />
                <asp:ValidationSummary ID="ModalValidationSummary" runat="server" ValidationGroup="ProductGroup" CssClass="alert-banner alert-error" HeaderText="Please fix the following issues:" />
                <asp:Label ID="ModalErrorMessage" runat="server" CssClass="alert-banner alert-error" Visible="false" />

                <div class="form-group">
                    <label for="<%= txtProductName.ClientID %>">Product Name <span class="req">*</span></label>
                    <asp:TextBox ID="txtProductName" runat="server" CssClass="form-control-input" MaxLength="150" placeholder="e.g., Crispy Pork Sisig Bowl" autocomplete="off" />
                    <asp:RequiredFieldValidator ID="rfvProductName" runat="server" ControlToValidate="txtProductName" ErrorMessage="Product name is required." Display="Dynamic" CssClass="field-error" ValidationGroup="ProductGroup" />
                </div>

                <div class="form-group">
                    <label for="<%= ddlModalCategory.ClientID %>">Category <span class="req">*</span></label>
                    <asp:DropDownList ID="ddlModalCategory" runat="server" CssClass="form-control-input" />
                    <asp:RequiredFieldValidator ID="rfvModalCategory" runat="server" ControlToValidate="ddlModalCategory" InitialValue="" ErrorMessage="Please select a food category." Display="Dynamic" CssClass="field-error" ValidationGroup="ProductGroup" />
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="<%= txtUnitPrice.ClientID %>">Selling Price (&#8369;) <span class="req">*</span></label>
                        <asp:TextBox ID="txtUnitPrice" runat="server" CssClass="form-control-input" placeholder="0.00" autocomplete="off" />
                        <asp:RequiredFieldValidator ID="rfvUnitPrice" runat="server" ControlToValidate="txtUnitPrice" ErrorMessage="Selling price is required." Display="Dynamic" CssClass="field-error" ValidationGroup="ProductGroup" />
                        <asp:RangeValidator ID="rvUnitPrice" runat="server" ControlToValidate="txtUnitPrice" Type="Double" MinimumValue="0.01" MaximumValue="999999.99" ErrorMessage="Price must be greater than &#8369;0." Display="Dynamic" CssClass="field-error" ValidationGroup="ProductGroup" />
                    </div>
                    <div class="form-group">
                        <label for="<%= txtCostPrice.ClientID %>">Cost Price (&#8369;)</label>
                        <asp:TextBox ID="txtCostPrice" runat="server" CssClass="form-control-input" placeholder="0.00" autocomplete="off" />
                        <asp:RangeValidator ID="rvCostPrice" runat="server" ControlToValidate="txtCostPrice" Type="Double" MinimumValue="0.00" MaximumValue="999999.99" ErrorMessage="Cost price cannot be negative." Display="Dynamic" CssClass="field-error" ValidationGroup="ProductGroup" />
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="<%= txtStockQty.ClientID %>">Stock Quantity (servings) <span class="req">*</span></label>
                        <asp:TextBox ID="txtStockQty" runat="server" CssClass="form-control-input" TextMode="Number" min="0" placeholder="0" />
                        <asp:RequiredFieldValidator ID="rfvStockQty" runat="server" ControlToValidate="txtStockQty" ErrorMessage="Stock quantity is required." Display="Dynamic" CssClass="field-error" ValidationGroup="ProductGroup" />
                    </div>
                    <div class="form-group">
                        <label for="<%= txtReorderLevel.ClientID %>">Reorder Alert Level <span class="req">*</span></label>
                        <asp:TextBox ID="txtReorderLevel" runat="server" CssClass="form-control-input" TextMode="Number" min="0" placeholder="5" />
                        <asp:RequiredFieldValidator ID="rfvReorderLevel" runat="server" ControlToValidate="txtReorderLevel" ErrorMessage="Reorder level is required." Display="Dynamic" CssClass="field-error" ValidationGroup="ProductGroup" />
                    </div>
                </div>

                <div class="form-group">
                    <label for="<%= txtDescription.ClientID %>">Description</label>
                    <asp:TextBox ID="txtDescription" runat="server" CssClass="form-control-input" TextMode="MultiLine" Rows="2" MaxLength="500" placeholder="Optional notes, dish description or portion details" />
                </div>
            </div>
            <div class="tracker-modal-footer">
                <asp:Button ID="btnCancelProduct" runat="server" Text="Cancel" CssClass="date-button" OnClick="BtnCloseModal_Click" CausesValidation="false" />
                <asp:Button ID="btnSaveProduct" runat="server" Text="Save to Database" CssClass="record-button" OnClick="BtnSaveProduct_Click" ValidationGroup="ProductGroup" />
            </div>
        </div>
    </asp:Panel>
</asp:Content>
