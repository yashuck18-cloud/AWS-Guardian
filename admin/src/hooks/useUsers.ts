import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { usersApi, UsersFilterParams } from '../api/users';

export const useUsers = (params?: UsersFilterParams) => {
  return useQuery({
    queryKey: ['admin-users', params],
    queryFn: () => usersApi.getUsers(params),
    staleTime: 15000,
  });
};

export const useUserDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-user-detail', id],
    queryFn: () => usersApi.getUserDetail(id),
    enabled: !!id,
  });
};

export const useToggleUserStatus = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => usersApi.toggleUserStatus(id),
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      queryClient.invalidateQueries({ queryKey: ['admin-user-detail', id] });
      queryClient.invalidateQueries({ queryKey: ['admin-dashboard'] });
    },
  });
};

export const useDeleteUser = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => usersApi.deleteUser(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      queryClient.invalidateQueries({ queryKey: ['admin-dashboard'] });
    },
  });
};
