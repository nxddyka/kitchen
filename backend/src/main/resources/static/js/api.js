/* ============================================================
   智能厨房辅助系统 · API 请求封装
   ============================================================ */

const API_BASE = '/kitchen/api';

const Api = {
    /** 基础请求方法 */
    async request(path, options = {}) {
        const url = path.startsWith('http') ? path : API_BASE + path;
        const token = Auth.getToken();

        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };

        if (token) {
            headers['Authorization'] = 'Bearer ' + token;
        }

        try {
            const response = await fetch(url, { ...options, headers });

            // 401 未登录：清除 token，跳转登录页
            if (response.status === 401) {
                Auth.clearToken();
                ToastManager.warning('登录已过期，请重新登录');
                setTimeout(() => { window.location.href = 'login'; }, 1500);
                return null;
            }

            // 403 无权限
            if (response.status === 403) {
                const data = await response.json();
                ToastManager.error(data.message || '无权限访问');
                return null;
            }

            const data = await response.json();
            return data;
        } catch (error) {
            console.error('API 请求失败:', error);
            ToastManager.error('网络请求失败，请检查服务是否启动');
            return null;
        }
    },

    /** GET 请求 */
    get(path, params = null) {
        let url = path;
        if (params) {
            const query = new URLSearchParams(params).toString();
            url += (url.includes('?') ? '&' : '?') + query;
        }
        return this.request(url, { method: 'GET' });
    },

    /** POST 请求 */
    post(path, body = null) {
        return this.request(path, {
            method: 'POST',
            body: body ? JSON.stringify(body) : null
        });
    },

    /** PUT 请求 */
    put(path, body = null) {
        return this.request(path, {
            method: 'PUT',
            body: body ? JSON.stringify(body) : null
        });
    },

    /** DELETE 请求 */
    delete(path) {
        return this.request(path, { method: 'DELETE' });
    }
};
