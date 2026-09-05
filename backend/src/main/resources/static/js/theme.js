/* ============================================================
   智能厨房辅助系统 · 公共 JS（Toast + Modal + 通用工具）
   ============================================================ */

/* Toast 通知工具类 */
class ToastManager {
    static icons = {
        success: 'fa-check-circle',
        error: 'fa-exclamation-circle',
        warning: 'fa-exclamation-triangle',
        info: 'fa-info-circle'
    };

    static getContainer() {
        let container = document.getElementById('messagesContainer');
        if (!container) {
            container = document.createElement('div');
            container.id = 'messagesContainer';
            container.className = 'messages-container';
            document.body.appendChild(container);
        }
        return container;
    }

    static show(message, type = 'success', duration = 3000) {
        const container = this.getContainer();
        const toast = document.createElement('div');
        toast.className = 'toast-notification toast-' + type;
        const icon = this.icons[type] || this.icons.success;
        toast.innerHTML = `<i class="fas ${icon}"></i><span class="toast-text">${message}</span>`;
        container.appendChild(toast);
        toast.offsetHeight;
        setTimeout(() => toast.classList.add('show'), 10);
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => toast.remove(), 300);
        }, duration);
    }

    static success(msg, d) { this.show(msg, 'success', d); }
    static error(msg, d) { this.show(msg, 'error', d); }
    static warning(msg, d) { this.show(msg, 'warning', d); }
    static info(msg, d) { this.show(msg, 'info', d); }
}

/* Modal 弹窗工具类 */
class ModalManager {
    static ensureDom() {
        let modal = document.getElementById('customModal');
        if (!modal) {
            modal = document.createElement('div');
            modal.className = 'modal-backdrop-custom';
            modal.id = 'customModal';
            modal.innerHTML = `
                <div class="modal-dialog-custom">
                    <div class="modal-header-custom">
                        <span id="modalTitle">提示</span>
                        <button class="modal-close-btn" onclick="ModalManager.close()">&times;</button>
                    </div>
                    <div class="modal-body-custom" id="modalBody"></div>
                    <div class="modal-footer-custom" id="modalFooter">
                        <button class="btn btn-secondary" onclick="ModalManager.close()">取消</button>
                        <button class="btn btn-primary" id="modalConfirmBtn">确定</button>
                    </div>
                </div>
            `;
            document.body.appendChild(modal);
            modal.addEventListener('click', function(e) {
                if (e.target === modal) ModalManager.close();
            });
            document.addEventListener('keydown', function(e) {
                if (e.key === 'Escape') ModalManager.close();
            });
        }
    }

    static open({ title = '提示', body = '', confirmText = '确定',
                   cancelText = '取消', onConfirm = null, showCancel = true }) {
        this.ensureDom();
        const backdrop = document.getElementById('customModal');
        document.getElementById('modalTitle').textContent = title;
        document.getElementById('modalBody').innerHTML = body;
        const confirmBtn = document.getElementById('modalConfirmBtn');
        confirmBtn.textContent = confirmText;
        const newBtn = confirmBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newBtn, confirmBtn);
        newBtn.id = 'modalConfirmBtn';
        if (onConfirm) {
            newBtn.addEventListener('click', () => {
                const result = onConfirm();
                if (result !== false) this.close();
            });
        } else {
            newBtn.addEventListener('click', () => this.close());
        }
        const cancelBtn = document.querySelector('#modalFooter .btn-secondary');
        cancelBtn.textContent = cancelText;
        cancelBtn.style.display = showCancel ? '' : 'none';
        backdrop.classList.add('show');
    }

    static alert(title, body, onClose = null) {
        this.open({ title, body, showCancel: false, confirmText: '知道了',
                     onConfirm: () => { if (onClose) onClose(); } });
    }

    static confirm(options) { this.open({ ...options, showCancel: true }); }

    static close() {
        const modal = document.getElementById('customModal');
        if (modal) modal.classList.remove('show');
    }
}

/* 通用工具函数 */
const Utils = {
    /** 获取 URL 查询参数 */
    getQueryParam(name) {
        const params = new URLSearchParams(window.location.search);
        return params.get(name);
    },

    /** 格式化时间 */
    formatTime(dateStr) {
        if (!dateStr) return '';
        const d = new Date(dateStr);
        return d.toLocaleString('zh-CN', { hour12: false });
    },

    /** 转义 HTML 防止 XSS */
    escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    /** 获取默认头像首字母 */
    getInitial(username) {
        if (!username) return 'U';
        return username.charAt(0).toUpperCase();
    }
};
