import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Bot, Shield, Zap, TrendingUp } from 'lucide-react';
import { ThemeToggle } from '@/components/ThemeToggle';

const Landing = () => {
  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border">
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Bot className="h-8 w-8 text-primary" />
            <span className="text-xl font-bold text-foreground">NextGen Vending</span>
          </div>
          <div className="flex items-center space-x-4">
            <ThemeToggle />
            <Button asChild variant="default">
              <Link to="/login">Login</Link>
            </Button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto text-center">
          <h1 className="text-4xl md:text-6xl font-bold text-foreground mb-6">
            NextGen Vending
          </h1>
          <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            AI Network Hub for Modern Vending Operations
          </p>
          <p className="text-lg text-muted-foreground mb-12 max-w-3xl mx-auto">
            Revolutionize your vending business with intelligent monitoring, predictive analytics, 
            and seamless inventory management. Transform every machine into a smart endpoint.
          </p>
          <Button asChild size="lg" className="text-lg px-8 py-6">
            <Link to="/login">Get Started</Link>
          </Button>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16 px-4 bg-muted/20">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold text-center text-foreground mb-12">
            Why Choose NextGen Vending?
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <Card className="border-border">
              <CardContent className="p-6 text-center">
                <Shield className="h-12 w-12 text-primary mx-auto mb-4" />
                <h3 className="text-xl font-semibold text-foreground mb-3">Smart Monitoring</h3>
                <p className="text-muted-foreground">
                  Real-time monitoring of all your vending machines with advanced alerts and notifications.
                </p>
              </CardContent>
            </Card>
            <Card className="border-border">
              <CardContent className="p-6 text-center">
                <Zap className="h-12 w-12 text-primary mx-auto mb-4" />
                <h3 className="text-xl font-semibold text-foreground mb-3">AI-Powered Insights</h3>
                <p className="text-muted-foreground">
                  Leverage machine learning to predict maintenance needs and optimize inventory levels.
                </p>
              </CardContent>
            </Card>
            <Card className="border-border">
              <CardContent className="p-6 text-center">
                <TrendingUp className="h-12 w-12 text-primary mx-auto mb-4" />
                <h3 className="text-xl font-semibold text-foreground mb-3">Revenue Optimization</h3>
                <p className="text-muted-foreground">
                  Maximize profits with data-driven product placement and dynamic pricing strategies.
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border py-8 px-4">
        <div className="container mx-auto text-center">
          <p className="text-muted-foreground">
            © 2024 NextGen Vending. Powering the future of automated retail.
          </p>
        </div>
      </footer>
    </div>
  );
};

export default Landing;