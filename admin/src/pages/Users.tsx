import React, { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Search,
  Users as UsersIcon,
  Filter,
  UserPlus,
  ChevronLeft,
  ChevronRight,
  UserX,
  UserCheck,
  Trash2,
} from 'lucide-react';
import { useUsers, useToggleUserStatus, useDeleteUser } from '../hooks/useUsers';
import { Card, CardContent } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { TableSkeleton } from '../components/common/Skeleton';
import { EmptyState, ConfirmationDialog } from '../components/common/EmptyState';
import { AdminUser } from '../types';
import { formatDate, formatTimeAgo } from '../utils/cn';

export const Users: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [statusFilter, setStatusFilter] = useState(searchParams.get('status') || 'all');
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const [userToToggle, setUserToToggle] = useState<AdminUser | null>(null);
  const [userToDelete, setUserToDelete] = useState<AdminUser | null>(null);

  const navigate = useNavigate();

  const { data, isLoading, refetch } = useUsers({
    search: search.trim() || undefined,
    status: statusFilter !== 'all' ? statusFilter : undefined,
  });

  const toggleMutation = useToggleUserStatus();
  const deleteMutation = useDeleteUser();

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    setSearchParams((prev) => {
      if (search) prev.set('search', search);
      else prev.delete('search');
      return prev;
    });
  };

  const usersList = data?.users || [];
  const paginatedUsers = usersList.slice((page - 1) * pageSize, page * pageSize);
  const totalPages = Math.ceil(usersList.length / pageSize) || 1;

  const handleConfirmToggle = async () => {
    if (!userToToggle) return;
    try {
      await toggleMutation.mutateAsync(userToToggle.id);
      setUserToToggle(null);
      refetch();
    } catch {
      // handled
    }
  };

  const handleConfirmDelete = async () => {
    if (!userToDelete) return;
    try {
      await deleteMutation.mutateAsync(userToDelete.id);
      setUserToDelete(null);
      refetch();
    } catch {
      // handled
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-guardian-text tracking-tight">Users</h1>
          <p className="text-xs text-guardian-muted mt-1">
            Manage platform users and their access
          </p>
        </div>

        <Button variant="primary" size="md" className="bg-brand-600 hover:bg-brand-700 text-white font-semibold h-9 px-4 text-xs gap-1.5 cursor-pointer shadow-sm">
          <UserPlus className="w-3.5 h-3.5" />
          <span>Invite User</span>
        </Button>
      </div>

      {/* Filter / Search Bar */}
      <Card className="bg-guardian-card border-guardian-border">
        <CardContent className="p-3 flex items-center justify-between gap-4">
          <form onSubmit={handleSearchSubmit} className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 text-guardian-muted absolute left-3 top-2.5 pointer-events-none" />
            <input
              type="text"
              placeholder="Search users..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-guardian-bg text-guardian-text placeholder:text-guardian-dimmed text-xs rounded-lg border border-guardian-border pl-9 pr-3 py-2 focus:outline-none focus:border-brand-500"
            />
          </form>

          <button className="flex items-center gap-1.5 px-3 py-2 rounded-lg bg-guardian-bg border border-guardian-border text-xs font-semibold text-guardian-text hover:border-guardian-borderHover transition-colors cursor-pointer">
            <Filter className="w-3.5 h-3.5" />
            <span>Filter</span>
          </button>
        </CardContent>
      </Card>

      {/* Users Table */}
      <Card className="bg-guardian-card border-guardian-border">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-guardian-border text-guardian-muted font-semibold text-[11px]">
                <th className="py-3.5 px-5">User</th>
                <th className="py-3.5 px-4">Role</th>
                <th className="py-3.5 px-4 text-center">AWS Accounts</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4">Last Login</th>
                <th className="py-3.5 px-4">Joined</th>
                <th className="py-3.5 px-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-guardian-border text-guardian-text">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="p-0">
                    <TableSkeleton rows={5} cols={7} />
                  </td>
                </tr>
              ) : paginatedUsers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-0">
                    <EmptyState
                      icon={<UsersIcon className="w-6 h-6 text-brand-500" />}
                      title="No registered users found"
                      description="No platform users matched your search criteria in the database."
                    />
                  </td>
                </tr>
              ) : (
                paginatedUsers.map((u) => (
                  <tr key={u.id} className="hover:bg-guardian-cardElevated transition-colors group">
                    {/* User Identity */}
                    <td className="py-3.5 px-5">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-brand-600/20 border border-brand-500/30 flex items-center justify-center text-brand-500 font-bold text-xs shrink-0">
                          {u.name?.[0]?.toUpperCase() || 'U'}
                        </div>
                        <div>
                          <div className="font-bold text-guardian-text leading-tight">{u.name || 'User'}</div>
                          <div className="text-[11px] text-guardian-muted font-mono mt-0.5">{u.email}</div>
                        </div>
                      </div>
                    </td>

                    {/* Role */}
                    <td className="py-3.5 px-4 font-medium text-guardian-text">
                      {u.is_superuser ? 'Admin' : u.is_staff ? 'Manager' : 'User'}
                    </td>

                    {/* AWS Accounts Count */}
                    <td className="py-3.5 px-4 text-center font-mono font-bold">
                      {u.aws_accounts_count || 0}
                    </td>

                    {/* Status Pill */}
                    <td className="py-3.5 px-4">
                      {u.is_active ? (
                        <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-500 border border-emerald-500/20 text-[11px] font-bold">
                          Active
                        </span>
                      ) : (
                        <span className="px-2.5 py-0.5 rounded-full bg-rose-500/10 text-rose-500 border border-rose-500/20 text-[11px] font-bold">
                          Inactive
                        </span>
                      )}
                    </td>

                    {/* Last Login */}
                    <td className="py-3.5 px-4 text-guardian-muted font-mono text-[11px]">
                      {u.last_login ? formatTimeAgo(u.last_login) : 'Never'}
                    </td>

                    {/* Joined */}
                    <td className="py-3.5 px-4 text-guardian-muted font-mono text-[11px]">
                      {formatDate(u.created_at)}
                    </td>

                    {/* Actions */}
                    <td className="py-3.5 px-5 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          onClick={() => setUserToToggle(u)}
                          title={u.is_active ? 'Suspend User' : 'Activate User'}
                          className="p-1.5 rounded text-guardian-muted hover:text-amber-500 transition-colors cursor-pointer"
                        >
                          {u.is_active ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
                        </button>
                        <button
                          onClick={() => setUserToDelete(u)}
                          title="Delete User"
                          className="p-1.5 rounded text-guardian-muted hover:text-rose-500 transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Custom Pagination */}
        {usersList.length > 0 && (
          <div className="px-5 py-3 border-t border-guardian-border flex items-center justify-between text-xs text-guardian-muted">
            <div>
              Showing 1 to {paginatedUsers.length} of {usersList.length} results
            </div>

            <div className="flex items-center gap-1 font-mono">
              <button
                disabled={page <= 1}
                onClick={() => setPage(page - 1)}
                className="p-1.5 rounded text-guardian-muted hover:text-guardian-text disabled:opacity-40 cursor-pointer"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span className="px-3 py-1 rounded font-bold bg-brand-600 text-white">
                Page {page} of {totalPages}
              </span>
              <button
                disabled={page >= totalPages}
                onClick={() => setPage(page + 1)}
                className="p-1.5 rounded text-guardian-muted hover:text-guardian-text disabled:opacity-40 cursor-pointer"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </Card>

      {/* Suspend / Activate Dialog */}
      <ConfirmationDialog
        isOpen={!!userToToggle}
        onClose={() => setUserToToggle(null)}
        onConfirm={handleConfirmToggle}
        isLoading={toggleMutation.isPending}
        title={userToToggle?.is_active ? 'Suspend User Account?' : 'Reactivate User Account?'}
        message={`Are you sure you want to change the status of ${userToToggle?.email}?`}
        confirmLabel={userToToggle?.is_active ? 'Suspend' : 'Activate'}
        isDanger={userToToggle?.is_active}
      />

      {/* Delete User Dialog */}
      <ConfirmationDialog
        isOpen={!!userToDelete}
        onClose={() => setUserToDelete(null)}
        onConfirm={handleConfirmDelete}
        isLoading={deleteMutation.isPending}
        title="Delete User Account?"
        message={`Are you sure you want to delete ${userToDelete?.email}? This action cannot be undone.`}
        confirmLabel="Delete"
        isDanger
      />
    </div>
  );
};
