import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, X, Users, Cloud, Layers, AlertTriangle, Loader2 } from 'lucide-react';
import { searchApi } from '../../api/systemHealth';
import { GlobalSearchResponse, SearchResultItem } from '../../types';

interface GlobalSearchModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const GlobalSearchModal: React.FC<GlobalSearchModalProps> = ({ isOpen, onClose }) => {
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState<GlobalSearchResponse['results']>({
    users: [],
    accounts: [],
    resources: [],
    alerts: [],
  });

  const navigate = useNavigate();

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'k' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        // toggle modal
      }
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  useEffect(() => {
    if (!query || query.length < 2) {
      setResults({ users: [], accounts: [], resources: [], alerts: [] });
      return;
    }

    const timer = setTimeout(async () => {
      setLoading(true);
      try {
        const res = await searchApi.globalSearch(query);
        if (res.success) {
          setResults(res.results);
        }
      } catch {
        // ignore
      } finally {
        setLoading(false);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [query]);

  if (!isOpen) return null;

  const handleSelect = (item: SearchResultItem) => {
    onClose();
    if (item.type === 'User') navigate(`/admin/users/${item.id}`);
    else if (item.type === 'AWS Account') navigate(`/admin/aws-accounts/${item.id}`);
    else if (item.type === 'Resource') navigate(`/admin/resources/${item.id}`);
    else if (item.type === 'Alert') navigate(`/admin/alerts/${item.id}`);
  };

  const hasResults =
    results.users.length > 0 ||
    results.accounts.length > 0 ||
    results.resources.length > 0 ||
    results.alerts.length > 0;

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-20 p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
      <div
        className="w-full max-w-xl bg-guardian-card border border-guardian-border rounded-xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-150"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Search Input Bar */}
        <div className="flex items-center gap-3 px-4 py-3.5 border-b border-guardian-border">
          <Search className="w-5 h-5 text-guardian-muted shrink-0" />
          <input
            autoFocus
            type="text"
            placeholder="Search users, AWS accounts, resources, alerts... (Type min 2 chars)"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="w-full bg-transparent text-guardian-text placeholder:text-guardian-dimmed text-sm focus:outline-none"
          />
          {loading && <Loader2 className="w-4 h-4 text-primary-light animate-spin shrink-0" />}
          <button onClick={onClose} className="text-guardian-muted hover:text-guardian-text p-1 rounded-md">
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Results Container */}
        <div className="max-h-96 overflow-y-auto p-3 space-y-4">
          {!query && (
            <div className="py-8 text-center text-xs text-guardian-muted">
              Start typing to search across the entire AWS Guardian platform...
            </div>
          )}

          {query && query.length >= 2 && !loading && !hasResults && (
            <div className="py-8 text-center text-xs text-guardian-muted">
              No matching records found for "{query}"
            </div>
          )}

          {/* Users */}
          {results.users.length > 0 && (
            <div>
              <div className="text-[10px] font-bold text-guardian-dimmed uppercase px-2 mb-1.5 flex items-center gap-1.5">
                <Users className="w-3 h-3" /> Users
              </div>
              <div className="space-y-1">
                {results.users.map((u) => (
                  <button
                    key={u.id}
                    onClick={() => handleSelect(u)}
                    className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-left hover:bg-white/5 transition-colors group"
                  >
                    <div>
                      <div className="text-xs font-semibold text-guardian-text group-hover:text-primary-light">{u.title}</div>
                      <div className="text-[11px] text-guardian-muted">{u.subtitle}</div>
                    </div>
                    <span className="text-[10px] text-guardian-dimmed bg-white/5 px-2 py-0.5 rounded">User</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Accounts */}
          {results.accounts.length > 0 && (
            <div>
              <div className="text-[10px] font-bold text-guardian-dimmed uppercase px-2 mb-1.5 flex items-center gap-1.5">
                <Cloud className="w-3 h-3" /> AWS Accounts
              </div>
              <div className="space-y-1">
                {results.accounts.map((a) => (
                  <button
                    key={a.id}
                    onClick={() => handleSelect(a)}
                    className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-left hover:bg-white/5 transition-colors group"
                  >
                    <div>
                      <div className="text-xs font-semibold text-guardian-text group-hover:text-primary-light">{a.title}</div>
                      <div className="text-[11px] text-guardian-muted font-mono">{a.subtitle}</div>
                    </div>
                    <span className="text-[10px] text-guardian-dimmed bg-white/5 px-2 py-0.5 rounded">Account</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Resources */}
          {results.resources.length > 0 && (
            <div>
              <div className="text-[10px] font-bold text-guardian-dimmed uppercase px-2 mb-1.5 flex items-center gap-1.5">
                <Layers className="w-3 h-3" /> Resources
              </div>
              <div className="space-y-1">
                {results.resources.map((r) => (
                  <button
                    key={r.id}
                    onClick={() => handleSelect(r)}
                    className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-left hover:bg-white/5 transition-colors group"
                  >
                    <div>
                      <div className="text-xs font-semibold text-guardian-text group-hover:text-primary-light">{r.title}</div>
                      <div className="text-[11px] text-guardian-muted">{r.subtitle}</div>
                    </div>
                    <span className="text-[10px] text-guardian-dimmed bg-white/5 px-2 py-0.5 rounded">Resource</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Alerts */}
          {results.alerts.length > 0 && (
            <div>
              <div className="text-[10px] font-bold text-guardian-dimmed uppercase px-2 mb-1.5 flex items-center gap-1.5">
                <AlertTriangle className="w-3 h-3" /> Alerts
              </div>
              <div className="space-y-1">
                {results.alerts.map((al) => (
                  <button
                    key={al.id}
                    onClick={() => handleSelect(al)}
                    className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-left hover:bg-white/5 transition-colors group"
                  >
                    <div>
                      <div className="text-xs font-semibold text-guardian-text group-hover:text-primary-light">{al.title}</div>
                      <div className="text-[11px] text-guardian-muted">{al.subtitle}</div>
                    </div>
                    <span className="text-[10px] text-guardian-critical/80 bg-guardian-critical/10 px-2 py-0.5 rounded">Alert</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-4 py-2 bg-guardian-bg/80 border-t border-guardian-border flex items-center justify-between text-[11px] text-guardian-dimmed">
          <span>Press <kbd className="px-1.5 py-0.5 rounded bg-white/10 font-mono text-[10px]">Esc</kbd> to close</span>
          <span>Global Cloud Search</span>
        </div>
      </div>
    </div>
  );
};
