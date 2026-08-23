import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Loading } from '@/components/ui/loading';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <Loading message="Loading..." size="lg" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // Check if user has completed onboarding
  // If any of these keys are missing, redirect to onboarding
  const requiredMetadata = ['full_name', 'theme', 'unit_system', 'timezone', 'two_factor_enabled'];
  const hasCompletedOnboarding = user.user_metadata?.profile_complete === true;
  
  // For development/testing, you can manually skip onboarding by setting this flag
  const skipOnboarding = user.user_metadata?.skip_onboarding === true;
  
  if (!hasCompletedOnboarding && !skipOnboarding) {
    return <Navigate to="/onboarding" replace />;
  }

  return <>{children}</>;
};