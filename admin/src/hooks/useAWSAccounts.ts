import { useQuery } from '@tanstack/react-query';
import { awsAccountsApi, AWSAccountsFilterParams } from '../api/awsAccounts';

export const useAWSAccounts = (params?: AWSAccountsFilterParams) => {
  return useQuery({
    queryKey: ['admin-aws-accounts', params],
    queryFn: () => awsAccountsApi.getAccounts(params),
    staleTime: 15000,
  });
};

export const useAWSAccountDetail = (id: string) => {
  return useQuery({
    queryKey: ['admin-aws-account-detail', id],
    queryFn: () => awsAccountsApi.getAccountDetail(id),
    enabled: !!id,
  });
};
