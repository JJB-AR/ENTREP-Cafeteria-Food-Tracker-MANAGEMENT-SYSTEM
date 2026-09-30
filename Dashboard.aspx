<%@ Page Title="Dashboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="ENTREP_Cafeteria_Food_Tracker_MANAGEMENT_SYSTEM.Dashboard" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main class="tracker-dashboard">
        <aside class="tracker-sidebar">
            <div class="brand"><span class="brand-mark"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 3v7M10 3v7M13 3v7M10 10v11M18 3c-2 2-2 6 0 8v10M18 3v8" /></svg></span><span><strong>ENTREP</strong><small>FOOD TRACKER</small></span></div>
            <nav class="tracker-nav" aria-label="Main navigation">
                <a class="active" href="#"><span aria-hidden="true">&#9638;</span>Overview</a>
                <a href="#"><span aria-hidden="true">&#10006;</span>Products</a>
                <a href="#"><span aria-hidden="true">&#9633;</span>Sales</a>
                <a href="#"><span aria-hidden="true">&#9618;</span>Analytics</a>
            </nav>
            <div class="target-card"><small>SEMESTER TARGET</small><strong>&#8369;45,000</strong><div class="target-bar"><i></i></div><span>68% achieved</span></div>
            <div class="profile"><b>AM</b><span><strong>Alex Mendoza</strong><small>ENTREP Student</small></span></div>
        </aside>

        <section class="tracker-content">
            <header class="dashboard-header">
                <div><h1>Good morning, <asp:Label ID="UsernameLabel" runat="server" Text="Alex" /></h1><p>Here's how your cafeteria products are performing today.</p></div>
                <div class="header-actions"><button type="button" class="date-button">&#9636; &nbsp; Sep 8–14, 2026 &#8964;</button><button type="button" class="record-button">&#65291; &nbsp; Record sale</button><asp:Button ID="LogoutButton" runat="server" Text="Sign out" CssClass="logout-button" OnClick="LogoutButton_Click" CausesValidation="false" /></div>
            </header>

            <div class="dashboard-grid">
                <section class="metric-stack">
                    <article class="metric-card"><div class="metric-icon mint">&#8369;</div><div><small>Total sales</small><strong>&#8369;12,840</strong></div><em>+18.2%</em></article>
                    <article class="metric-card"><div class="metric-icon peach">&#9633;</div><div><small>Items sold</small><strong>486</strong></div><em>+12.5%</em></article>
                    <article class="metric-card"><div class="metric-icon lavender">&#9641;</div><div><small>Transactions</small><strong>214</strong></div><em>+8.4%</em></article>
                </section>
                <section class="panel trend-panel"><div class="panel-heading"><div><h2>Sales trend</h2><p>Revenue over the last 7 days</p></div><span class="legend"><i></i>Daily revenue</span></div><div class="chart"><i style="height:54%"><label>Mon</label></i><i style="height:70%"><label>Tue</label></i><i style="height:61%"><label>Wed</label></i><i style="height:91%"><label>Thu</label></i><i style="height:80%"><label>Fri</label></i><i class="highlight" style="height:100%"><label>Sat</label></i><i style="height:96%"><label>Sun</label></i></div></section>
            </div>

            <div class="lower-grid">
                <section class="panel product-panel"><div class="panel-heading"><div><h2>Product performance</h2><p>Track quantity sold, revenue and sales frequency</p></div><button type="button" class="add-button">&#65291; &nbsp; Add product</button></div><div class="product-table"><div class="table-head"><span class="product-head">PRODUCT</span><span>PRICE</span><span>SOLD</span><span>REVENUE</span><span>TREND</span></div><div class="product-row"><b class="product-color orange">&#9832;</b><strong>Chicken Rice Bowl<small>Meals</small></strong><span>&#8369;65</span><span>128</span><strong>&#8369;8,320</strong><em>+24%</em><span>•••</span></div><div class="product-row"><b class="product-color blue">&#9832;</b><strong>Tuna Sandwich<small>Snacks</small></strong><span>&#8369;45</span><span>96</span><strong>&#8369;4,320</strong><em>+18%</em><span>•••</span></div><div class="product-row"><b class="product-color brown">&#9832;</b><strong>Iced Milo<small>Drinks</small></strong><span>&#8369;30</span><span>84</span><strong>&#8369;2,520</strong><em>+9%</em><span>•••</span></div><div class="product-row"><b class="product-color yellow">&#9832;</b><strong>Banana Cue<small>Snacks</small></strong><span>&#8369;25</span><span>72</span><strong>&#8369;1,800</strong><em class="down">−3%</em><span>•••</span></div></div><a class="panel-link" href="#">View all 12 products</a></section>
                <section class="panel sales-panel"><div class="panel-heading"><div><h2>Recent sales</h2><p>Today · 38 transactions</p></div><button type="button" class="filter-button">&#9776;</button></div><div class="sales-list"><div class="sale-row"><b>&#8369;</b><span>#0214<small>2× Rice Bowl, 1× Iced Milo</small></span><time>10:42 AM</time><strong>&#8369;160</strong></div><div class="sale-row"><b>&#8369;</b><span>#0213<small>2× Tuna Sandwich</small></span><time>10:31 AM</time><strong>&#8369;90</strong></div><div class="sale-row"><b>&#8369;</b><span>#0212<small>3× Banana Cue</small></span><time>10:18 AM</time><strong>&#8369;75</strong></div><div class="sale-row"><b>&#8369;</b><span>#0211<small>1× Rice Bowl</small></span><time>9:56 AM</time><strong>&#8369;65</strong></div></div><div class="low-stock">&#9888; <span><strong>Low stock alert</strong><small>Tuna Sandwich has 8 servings left.</small></span><a href="#">Update</a></div><a class="panel-link" href="#">View all transactions</a></section>
            </div>
        </section>
    </main>
</asp:Content>
