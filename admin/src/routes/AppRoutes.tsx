import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from './ProtectedRoute';
import { AdminLayout } from '../components/layout/AdminLayout';

// Pages
import { Login } from '../pages/Login';
import { Dashboard } from '../pages/Dashboard';
import { Users } from '../pages/Users';
import { UserDetails } from '../pages/UserDetails';
import { AWSAccounts } from '../pages/AWSAccounts';
import { AWSAccountDetails } from '../pages/AWSAccountDetails';
import { Resources } from '../pages/Resources';
import { ResourceDetails } from '../pages/ResourceDetails';
import { Alerts } from '../pages/Alerts';
import { AlertDetails } from '../pages/AlertDetails';
import { Scans } from '../pages/Scans';
import { Notifications } from '../pages/Notifications';
import { AuditLogs } from '../pages/AuditLogs';
import { Analytics } from '../pages/Analytics';
import { Settings } from '../pages/Settings';
import { NotFound } from '../pages/NotFound';

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      {/* Public Login Route */}
      <Route path="/login" element={<Login />} />

      {/* Root redirect to /admin */}
      <Route path="/" element={<Navigate to="/admin" replace />} />

      {/* Protected Admin Routes with Layout */}
      <Route
        path="/admin"
        element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Dashboard />} />
        
        {/* Users */}
        <Route path="users" element={<Users />} />
        <Route path="users/:id" element={<UserDetails />} />

        {/* AWS Accounts */}
        <Route path="aws-accounts" element={<AWSAccounts />} />
        <Route path="aws-accounts/:id" element={<AWSAccountDetails />} />

        {/* Resources */}
        <Route path="resources" element={<Resources />} />
        <Route path="resources/:id" element={<ResourceDetails />} />

        {/* Alerts */}
        <Route path="alerts" element={<Alerts />} />
        <Route path="alerts/:id" element={<AlertDetails />} />

        {/* Scans */}
        <Route path="scans" element={<Scans />} />

        {/* Notifications */}
        <Route path="notifications" element={<Notifications />} />

        {/* Audit Logs */}
        <Route path="audit-logs" element={<AuditLogs />} />

        {/* Analytics */}
        <Route path="analytics" element={<Analytics />} />

        {/* Settings */}
        <Route path="settings" element={<Settings />} />

        {/* 404 inside layout */}
        <Route path="*" element={<NotFound />} />
      </Route>

      {/* Catch-all */}
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
};
