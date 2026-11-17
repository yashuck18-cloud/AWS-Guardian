import { apiClient } from './client';
import { AdminUser } from '../types';

export interface LoginPayload {
  email: string;
  password: string;
}

export interface LoginResponse {
  success: boolean;
  message: string;
  token: string;
  user: AdminUser;
}

export const authApi = {
  login: async (payload: LoginPayload): Promise<LoginResponse> => {
    const res = await apiClient.post<LoginResponse>('/auth/login/', payload);
    return res.data;
  },

  getProfile: async (): Promise<{ success: boolean; user: AdminUser }> => {
    const res = await apiClient.get<{ success: boolean; user: AdminUser }>('/auth/profile/');
    return res.data;
  },

  updateProfile: async (data: Partial<AdminUser>): Promise<{ success: boolean; user: AdminUser }> => {
    const res = await apiClient.patch<{ success: boolean; user: AdminUser }>('/auth/profile/', data);
    return res.data;
  },

  changePassword: async (data: { old_password: string; new_password: string }): Promise<{ success: boolean; message: string; token: string }> => {
    const res = await apiClient.post('/auth/change-password/', data);
    return res.data;
  },

  forgotPassword: async (email: string): Promise<{ success: boolean; message: string }> => {
    const res = await apiClient.post('/auth/forgot-password/', { email });
    return res.data;
  },
};
