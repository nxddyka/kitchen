/* ============================================================
   智能厨房辅助系统 · 认证状态管理
   ============================================================ */

const Auth = {
    /** 获取 Token */
    getToken() {
        return localStorage.getItem('kitchen_token');
    },

    /** 获取用户信息 */
    getUser() {
        const userStr = localStorage.getItem('kitchen_user');
        if (!userStr) return null;
        try {
            return JSON.parse(userStr);
        } catch {
            return null;
        }
    },

    /** 获取用户 ID */
    getUserId() {
        const user = this.getUser();
        return user ? user.id : null;
    },

    /** 获取用户名 */
    getUsername() {
        const user = this.getUser();
        return user ? user.username : '';
    },

    /** 获取角色（0普通用户 1版主 2管理员） */
    getRole() {
        const user = this.getUser();
        return user ? user.role : -1;
    },

    /** 是否已登录 */
    isLoggedIn() {
        return !!this.getToken();
    },

    /** 是否为管理员 */
    isAdmin() {
        return this.getRole() === 2;
    },

    /** 保存登录信息 */
    saveLogin(token, user) {
        localStorage.setItem('kitchen_token', token);
        localStorage.setItem('kitchen_user', JSON.stringify(user));
    },

    /** 清除登录信息 */
    clearToken() {
        localStorage.removeItem('kitchen_token');
        localStorage.removeItem('kitchen_user');
    },

    /** 退出登录 */
    logout() {
        this.clearToken();
        window.location.href = 'login';
    },

    /** 检查登录状态，未登录则跳转登录页 */
    requireLogin() {
        if (!this.isLoggedIn()) {
            ToastManager.warning('请先登录');
            setTimeout(() => { window.location.href = 'login'; }, 1000);
            return false;
        }
        return true;
    },

    /** 登录成功后根据角色跳转 */
    redirectByRole() {
        if (this.isAdmin()) {
            window.location.href = 'ingredients';
        } else {
            window.location.href = 'ingredients';
        }
    }
};

/* 生成导航栏 HTML */
function renderNavbar(activePage = '') {
    const loggedIn = Auth.isLoggedIn();
    const username = Auth.getUsername();
    const initial = Utils.getInitial(username);
    const isAdmin = Auth.isAdmin();

    const navItems = [
        { key: 'recipes', label: '菜谱中心', href: 'ingredients' },
        { key: 'ingredients', label: '食材库', href: 'ingredients' },
        { key: 'forum', label: '论坛', href: 'forum' },
    ];

    // 管理员可见 Swagger 入口
    if (isAdmin) {
        navItems.push({ key: 'admin', label: 'API文档', href: 'http://localhost:8080/kitchen/doc.html', external: true });
    }

    const navItemsHtml = navItems.map(item => {
        const active = item.key === activePage ? 'active' : '';
        const target = item.external ? 'target="_blank"' : '';
        return `<li class="nav-item"><a class="nav-link ${active}" href="${item.href}" ${target}>${item.label}</a></li>`;
    }).join('');

    let rightNav;
    if (loggedIn) {
        rightNav = `
            <li class="nav-item">
                <a class="nav-link user-welcome" href="profile">
                    <span>欢迎，${Utils.escapeHtml(username)}</span>
                    <div class="nav-avatar"><div class="nav-avatar-default">${initial}</div></div>
                </a>
            </li>`;
    } else {
        rightNav = `
            <li class="nav-item"><a class="nav-link" href="login">登录</a></li>
            <li class="nav-item"><a class="nav-link" href="login#register">注册</a></li>`;
    }

    return `
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="ingredients">
                <i class="fas fa-utensils"></i>
                <span>智能厨房</span>
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    ${navItemsHtml}
                </ul>
                <div class="search-container">
                    <div class="search-wrapper">
                        <button class="search-icon-btn" onclick="performSearch()">
                            <i class="fas fa-search"></i>
                        </button>
                        <input type="text" id="searchInput" placeholder="搜索菜谱或食材..." class="search-input"
                               value="${Utils.escapeHtml(Utils.getQueryParam('q') || '')}" />
                    </div>
                </div>
                <ul class="navbar-nav">
                    ${rightNav}
                </ul>
            </div>
        </div>
    </nav>`;
}

/* 生成页脚 HTML */
function renderFooter() {
    return `
    <footer>
        <div class="container">
            <p>&copy; 2026 智能厨房辅助系统 · AI驱动的食材识别与菜谱推荐平台</p>
        </div>
    </footer>`;
}

/* 搜索函数 */
function performSearch() {
    const query = document.getElementById('searchInput').value.trim();
    if (!query) {
        ToastManager.warning('请输入搜索内容');
        return;
    }
    window.location.href = 'ingredients?q=' + encodeURIComponent(query);
}
