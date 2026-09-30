<%@ Page Title="Login" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Login" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="login-page">
        <div class="login-brand"><span class="brand-mark">??</span><span><strong>ENTREP</strong><small>FOOD TRACKER</small></span></div>
        <section class="login-card">
            <div class="login-intro"><span class="login-icon">?</span><h1>Welcome back</h1><p>Sign in to manage your cafeteria food tracker.</p></div>
            <asp:ValidationSummary ID="ValidationSummary1" runat="server" CssClass="login-error" />
            <div class="login-field"><asp:Label ID="UsernameLabel" runat="server" AssociatedControlID="UsernameTextBox">Username</asp:Label><asp:TextBox ID="UsernameTextBox" runat="server" CssClass="login-input" MaxLength="50" autocomplete="username" placeholder="Enter your username" /><asp:RequiredFieldValidator ID="UsernameRequired" runat="server" ControlToValidate="UsernameTextBox" ErrorMessage="Username is required." CssClass="field-error" Display="Dynamic" /></div>
            <div class="login-field"><asp:Label ID="PasswordLabel" runat="server" AssociatedControlID="PasswordTextBox">Password</asp:Label><asp:TextBox ID="PasswordTextBox" runat="server" CssClass="login-input" TextMode="Password" MaxLength="100" autocomplete="current-password" placeholder="Enter your password" /><asp:RequiredFieldValidator ID="PasswordRequired" runat="server" ControlToValidate="PasswordTextBox" ErrorMessage="Password is required." CssClass="field-error" Display="Dynamic" /></div>
            <asp:Label ID="ErrorMessage" runat="server" CssClass="login-error" Visible="false" />
            <asp:Button ID="LoginButton" runat="server" Text="Sign in to dashboard  ?" CssClass="login-submit" OnClick="LoginButton_Click" />
            <p class="login-hint">Demo account: <strong>admin</strong> · password configured in Web.config</p>
        </section>
        <p class="login-footer">© 2026 ENTREP Food Tracker · Built for better cafeteria management</p>
    </main>
</asp:Content>
