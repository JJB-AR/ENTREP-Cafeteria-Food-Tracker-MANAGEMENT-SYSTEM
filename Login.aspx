<%@ Page Title="Login" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Login" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="login-page">
        <table class="login-layout" cellpadding="0" cellspacing="0" role="presentation">
            <tr>
                <td>
                    <table class="login-brand" cellpadding="0" cellspacing="0" role="presentation">
                        <tr>
                            <td><span class="brand-mark"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 3v7M10 3v7M13 3v7M10 10v11M18 3c-2 2-2 6 0 8v10M18 3v8" /></svg></span></td>
                            <td><strong>ENTREP</strong><small>FOOD TRACKER</small></td>
                        </tr>
                    </table>
                    <div class="login-card">
                        <div class="login-intro">
                            <span class="login-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 19V5M4 19h17M8 15l4-4 3 2 5-7" /></svg></span>
                            <h1>Cafeteria Food Tracker</h1>
                            <p class="login-description">A simple sales-tracking system for entrepreneurship students to manage cafeteria products and understand how they perform.</p>
                        </div>
                        
                        <h2 class="login-form-heading">Sign in to continue</h2>
                        <asp:ValidationSummary ID="ValidationSummary1" runat="server" CssClass="login-error" />
                        <div class="login-field">
                            <asp:Label ID="UsernameLabel" runat="server" AssociatedControlID="UsernameTextBox">Username</asp:Label>
                            <asp:TextBox ID="UsernameTextBox" runat="server" CssClass="login-input" MaxLength="50" autocomplete="username" placeholder="Enter your username" />
                            <asp:RequiredFieldValidator ID="UsernameRequired" runat="server" ControlToValidate="UsernameTextBox" ErrorMessage="Username is required." CssClass="field-error" Display="Dynamic" />
                        </div>
                        <div class="login-field">
                            <asp:Label ID="PasswordLabel" runat="server" AssociatedControlID="PasswordTextBox">Password</asp:Label>
                            <asp:TextBox ID="PasswordTextBox" runat="server" CssClass="login-input" TextMode="Password" MaxLength="100" autocomplete="current-password" placeholder="Enter your password" />
                            <asp:RequiredFieldValidator ID="PasswordRequired" runat="server" ControlToValidate="PasswordTextBox" ErrorMessage="Password is required." CssClass="field-error" Display="Dynamic" />
                        </div>
                        <asp:Label ID="ErrorMessage" runat="server" CssClass="login-error" Visible="false" />
                        <asp:Button ID="LoginButton" runat="server" Text="Sign in to dashboard " CssClass="login-submit" OnClick="LoginButton_Click" />
                    </div>
                    <p class="login-footer">&#169; 2026 ENTREP Food Tracker. Built for organized cafeteria sales management.</p>
                </td>
            </tr>
        </table>
    </main>
</asp:Content>
