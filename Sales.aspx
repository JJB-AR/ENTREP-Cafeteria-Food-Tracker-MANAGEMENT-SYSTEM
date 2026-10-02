<%@ Page Title="Sales" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Sales.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Sales" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard">
        <table class="dashboard-shell" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td class="tracker-sidebar"></td>
                <td class="tracker-content">
                    <header class="screen-header">
                        <div>
                            <h1>Sales</h1>
                            <p>Review transactions and monitor live cafeteria sales activity in SQL.</p>
                        </div>
                        <div class="header-actions">
                            <asp:Button ID="BtnOpenRecordSale" runat="server" Text="&#65291; &nbsp; Record Sale" CssClass="record-button" OnClick="BtnOpenRecordSale_Click" CausesValidation="false" />
                        </div>
                    </header>

                    <asp:Panel ID="SaleAlertPanel" runat="server" Visible="false" CssClass="alert-banner alert-success">
                        <span><asp:Literal ID="SaleAlertMessage" runat="server" /></span>
                        <asp:LinkButton ID="btnDismissSaleAlert" runat="server" OnClick="BtnDismissSaleAlert_Click" CausesValidation="false" aria-label="Close notification">&times;</asp:LinkButton>
                    </asp:Panel>

                    <table class="summary-grid" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>
                                <div class="summary-card">
                                    <small>Today's sales</small>
                                    <strong>&#8369;<asp:Literal ID="SalesTotalValue" runat="server" /></strong>
                                    <span><asp:Literal ID="TodayDateText" runat="server" /></span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card">
                                    <small>Transactions today</small>
                                    <strong><asp:Literal ID="TodayTransactionCount" runat="server" /></strong>
                                    <span>Completed sales</span>
                                </div>
                            </td>
                            <td>
                                <div class="summary-card">
                                    <small>Average transaction</small>
                                    <strong>&#8369;<asp:Literal ID="AverageSaleValue" runat="server" /></strong>
                                    <span>Based on today's sales</span>
                                </div>
                            </td>
                        </tr>
                    </table>

                    <section class="panel screen-panel">
                        <div class="filter-toolbar">
                            <div>
                                <h2>Recent transactions</h2>
                                <p><asp:Literal ID="SalesRowsText" runat="server" /></p>
                            </div>
                            <div class="filter-group">
                                <asp:TextBox ID="txtSaleSearch" runat="server" CssClass="form-control-input" style="width:180px;" placeholder="Search cashier, product..." AutoPostBack="true" OnTextChanged="FilterSales" />
                                <asp:DropDownList ID="ddlSessionFilter" runat="server" CssClass="static-select" AutoPostBack="true" OnSelectedIndexChanged="FilterSales">
                                    <asp:ListItem Text="All sessions" Value="" />
                                    <asp:ListItem Text="Morning" Value="Morning" />
                                    <asp:ListItem Text="Afternoon" Value="Afternoon" />
                                    <asp:ListItem Text="Evening" Value="Evening" />
                                </asp:DropDownList>
                                <asp:DropDownList ID="ddlPaymentFilter" runat="server" CssClass="static-select" AutoPostBack="true" OnSelectedIndexChanged="FilterSales">
                                    <asp:ListItem Text="All payment methods" Value="" />
                                    <asp:ListItem Text="Cash" Value="Cash" />
                                    <asp:ListItem Text="GCash" Value="GCash" />
                                    <asp:ListItem Text="Maya" Value="Maya" />
                                </asp:DropDownList>
                            </div>
                        </div>

                        <div class="table-responsive">
                            <table class="data-table transaction-list" cellpadding="0" cellspacing="0">
                                <asp:Repeater ID="SalesRepeater" runat="server">
                                    <HeaderTemplate>
                                        <tr>
                                            <th>TRANSACTION</th>
                                            <th>TIME</th>
                                            <th>ITEMS</th>
                                            <th>SESSION</th>
                                            <th>CASHIER</th>
                                            <th>PAYMENT</th>
                                            <th align="right">TOTAL</th>
                                        </tr>
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <tr>
                                            <td><strong><%#: Eval("FormattedID") %></strong></td>
                                            <td><%#: Eval("TransactionDate", "{0:MMM d, yyyy h:mm tt}") %></td>
                                            <td><%#: Eval("Items") %></td>
                                            <td><span class="static-select" style="padding:2px 6px;font-size:9px;"><%#: Eval("SaleSession") %></span></td>
                                            <td><%#: Eval("RecordedBy") %></td>
                                            <td><span class="status-pill paid"><%#: Eval("PaymentMethod") %></span></td>
                                            <td align="right"><strong>&#8369;<%#: Eval("NetAmount", "{0:N2}") %></strong></td>
                                        </tr>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </table>
                        </div>

                        <asp:Panel ID="EmptySalesPanel" runat="server" Visible="false" CssClass="empty-data-state">
                            <p>No sales transactions match the current filter criteria.</p>
                        </asp:Panel>
                    </section>
                </td>
            </tr>
        </table>
    </main>

    <!-- Record Sale Modal -->
    <asp:Panel ID="SaleModal" runat="server" CssClass="tracker-modal-overlay" Visible="false">
        <div class="tracker-modal-card" role="dialog" aria-modal="true" aria-labelledby="saleModalHeading">
            <div class="tracker-modal-header">
                <div>
                    <h2 id="saleModalHeading">Record Sales Transaction</h2>
                    <p>Saves transaction header and line items directly to SQL, deducting stock automatically.</p>
                </div>
                <asp:LinkButton ID="btnCloseSaleModal" runat="server" CssClass="modal-close-btn" OnClick="BtnCloseSaleModal_Click" CausesValidation="false" aria-label="Close dialog">&times;</asp:LinkButton>
            </div>
            <div class="tracker-modal-body">
                <asp:ValidationSummary ID="SaleValidationSummary" runat="server" ValidationGroup="SaleGroup" CssClass="alert-banner alert-error" HeaderText="Please fix the following issues:" />
                <asp:Label ID="SaleErrorMessage" runat="server" CssClass="alert-banner alert-error" Visible="false" />

                <div class="form-group">
                    <label for="<%= ddlSaleProduct.ClientID %>">Food Product <span class="req">*</span></label>
                    <asp:DropDownList ID="ddlSaleProduct" runat="server" CssClass="form-control-input" />
                    <asp:RequiredFieldValidator ID="rfvSaleProduct" runat="server" ControlToValidate="ddlSaleProduct" InitialValue="" ErrorMessage="Please select a product." Display="Dynamic" CssClass="field-error" ValidationGroup="SaleGroup" />
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="<%= txtSaleQuantity.ClientID %>">Quantity to Sell <span class="req">*</span></label>
                        <asp:TextBox ID="txtSaleQuantity" runat="server" CssClass="form-control-input" TextMode="Number" min="1" Text="1" />
                        <asp:RequiredFieldValidator ID="rfvSaleQuantity" runat="server" ControlToValidate="txtSaleQuantity" ErrorMessage="Quantity is required." Display="Dynamic" CssClass="field-error" ValidationGroup="SaleGroup" />
                        <asp:RangeValidator ID="rvSaleQuantity" runat="server" ControlToValidate="txtSaleQuantity" Type="Integer" MinimumValue="1" MaximumValue="9999" ErrorMessage="Quantity must be at least 1." Display="Dynamic" CssClass="field-error" ValidationGroup="SaleGroup" />
                    </div>
                    <div class="form-group">
                        <label for="<%= ddlSaleSession.ClientID %>">Cafeteria Session <span class="req">*</span></label>
                        <asp:DropDownList ID="ddlSaleSession" runat="server" CssClass="form-control-input">
                            <asp:ListItem Text="Morning" Value="Morning" />
                            <asp:ListItem Text="Afternoon" Value="Afternoon" Selected="True" />
                            <asp:ListItem Text="Evening" Value="Evening" />
                            <asp:ListItem Text="All Day" Value="All Day" />
                        </asp:DropDownList>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="<%= ddlSalePaymentMethod.ClientID %>">Payment Method <span class="req">*</span></label>
                        <asp:DropDownList ID="ddlSalePaymentMethod" runat="server" CssClass="form-control-input">
                            <asp:ListItem Text="Cash" Value="Cash" Selected="True" />
                            <asp:ListItem Text="GCash" Value="GCash" />
                            <asp:ListItem Text="Maya" Value="Maya" />
                        </asp:DropDownList>
                    </div>
                    <div class="form-group">
                        <label for="<%= txtSaleDiscount.ClientID %>">Discount Amount (&#8369;)</label>
                        <asp:TextBox ID="txtSaleDiscount" runat="server" CssClass="form-control-input" Text="0.00" placeholder="0.00" />
                        <asp:RangeValidator ID="rvSaleDiscount" runat="server" ControlToValidate="txtSaleDiscount" Type="Double" MinimumValue="0.00" MaximumValue="99999.99" ErrorMessage="Discount cannot be negative." Display="Dynamic" CssClass="field-error" ValidationGroup="SaleGroup" />
                    </div>
                </div>

                <div class="form-group">
                    <label for="<%= txtSaleCashier.ClientID %>">Cashier / Recorded By</label>
                    <asp:TextBox ID="txtSaleCashier" runat="server" CssClass="form-control-input" MaxLength="100" />
                </div>

                <div class="form-group">
                    <label for="<%= txtSaleNotes.ClientID %>">Transaction Notes</label>
                    <asp:TextBox ID="txtSaleNotes" runat="server" CssClass="form-control-input" TextMode="MultiLine" Rows="2" MaxLength="500" placeholder="Optional notes (e.g. Faculty lunch order)" />
                </div>
            </div>
            <div class="tracker-modal-footer">
                <asp:Button ID="btnCancelSale" runat="server" Text="Cancel" CssClass="date-button" OnClick="BtnCloseSaleModal_Click" CausesValidation="false" />
                <asp:Button ID="btnSubmitSale" runat="server" Text="Record & Deduct Stock" CssClass="record-button" OnClick="BtnSubmitSale_Click" ValidationGroup="SaleGroup" />
            </div>
        </div>
    </asp:Panel>
</asp:Content>
