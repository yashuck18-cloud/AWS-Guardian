import { useQuery } from '@tanstack/react-query';
import { resourcesApi, ResourcesFilterParams } from '../api/resources';

export const useResources = (params?: ResourcesFilterParams) => {
  return useQuery({
    queryKey: ['admin-resources', params],
    queryFn: () => resourcesApi.getResources(params),
    staleTime: 15000,
  });
};

export const useResourceDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-resource-detail', id],
    queryFn: () => resourcesApi.getResourceDetail(id),
    enabled: !!id,
  });
};
