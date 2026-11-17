import React, { createContext, useContext, useState, useEffect } from 'react';
import { AdminUser } from '../types';
import { authApi, LoginPayload } from '../api/auth';

interface AuthContextType {
  user: AdminUser | null;
  token: string | null;
  isAuthenticated: boolean;
  isAdmin: boolean;
  isLoading: boolean;
  login: (payload: LoginPayload) => Promise<void>;
  logout: () => void;
  updateUser: (updatedUser: AdminUser) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<AdminUser | null>(() => {
    try {
      const stored = localStorage.getItem('guardian_admin_user');
      return stored ? JSON.parse(stored) : null;
    } catch {
      return null;
    }
  });

  const [token, setToken] = useState<string | null>(() => {
    return localStorage.getItem('guardian_admin_token');
  });

  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    const verifySession = async () => {
      const storedToken = localStorage.getItem('guardian_admin_token');
      if (storedToken) {
        try {
          const res = await authApi.getProfile();
          if (res.success && (res.user.is_staff || res.user.is_superuser)) {
            setUser(res.user);
            localStorage.setItem('guardian_admin_user', JSON.stringify(res.user));
          } else {
            // User does not have admin permissions
            logout();
          }
        } catch {
          logout();
        }
      }
      setIsLoading(false);
    };

    verifySession();
  }, []);

  const login = async (payload: LoginPayload) => {
    const res = await authApi.login(payload);
    if (!res.user.is_staff && !res.user.is_superuser) {
      throw new Error('Access denied. This console is restricted to AWS Guardian platform administrators.');
    }

    setToken(res.token);
    setUser(res.user);
    localStorage.setItem('guardian_admin_token', res.token);
    localStorage.setItem('guardian_admin_user', JSON.stringify(res.user));
  };

  const logout = () => {
    setToken(null);
    setUser(null);
    localStorage.removeItem('guardian_admin_token');
    localStorage.removeItem('guardian_admin_user');
  };

  const updateUser = (updatedUser: AdminUser) => {
    setUser(updatedUser);
    localStorage.setItem('guardian_admin_user', JSON.stringify(updatedUser));
  };

  const isAuthenticated = !!token && !!user;
  const isAdmin = !!user && (user.is_staff || user.is_superuser);

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated,
        isAdmin,
        isLoading,
        login,
        logout,
        updateUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
