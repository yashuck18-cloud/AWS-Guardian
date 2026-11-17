import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 25000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor: attach JWT token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('guardian_admin_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor: handle 401/403 and format clean errors
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError<any>) => {
    if (error.response) {
      const isLoginRequest = error.config?.url?.includes('/auth/login');
      if (error.response.status === 401 && !isLoginRequest) {
        localStorage.removeItem('guardian_admin_token');
        localStorage.removeItem('guardian_admin_user');
        if (window.location.pathname !== '/login') {
          window.location.href = '/login?expired=1';
        }
      }
      
      if ([502, 503, 504].includes(error.response.status)) {
        return Promise.reject(new Error('Backend API is not reachable. Please make sure the Django server is running at http://127.0.0.1:8000.'));
      }

      let message = error.response.data?.message || error.response.data?.detail;
      if (!message) {
        if (typeof error.response.data === 'string') {
          message = error.response.data.includes('<html') || error.response.data.includes('<!DOCTYPE')
            ? `Server error (${error.response.status}). Please check backend logs.`
            : error.response.data;
        } else if (error.response.data?.errors) {
          const errors = error.response.data.errors;
          message = typeof errors === 'string' ? errors : JSON.stringify(errors);
        } else {
          message = 'An unexpected server error occurred.';
        }
      }
      
      return Promise.reject(new Error(message));
    } else if (error.request) {
      return Promise.reject(new Error('Network error: Unable to connect to Django API server. Please check backend is running at http://127.0.0.1:8000.'));
    }
    return Promise.reject(error);
  }
);
