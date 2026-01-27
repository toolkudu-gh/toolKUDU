import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { createPageUrl } from '@/utils';
import { base44 } from '@/api/base44Client';
import { Button } from "@/components/ui/button";
import { 
  Home, Wrench, Inbox, User, Menu, X, LogIn, LogOut, Leaf
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

const navItems = [
  { name: 'Home', icon: Home, page: 'Home' },
  { name: 'My Tools', icon: Wrench, page: 'MyTools' },
  { name: 'Requests', icon: Inbox, page: 'Requests' },
];

export default function Layout({ children, currentPageName }) {
  const [user, setUser] = useState(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => {});
  }, []);

  const isActive = (page) => currentPageName === page;

  return (
    <div className="min-h-screen bg-stone-50">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white/80 backdrop-blur-xl border-b border-stone-100">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <Link to={createPageUrl('Home')} className="flex items-center gap-2">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#6B8E7B] to-[#5a7a69] flex items-center justify-center">
                <Leaf className="w-5 h-5 text-white" />
              </div>
              <span className="font-bold text-xl text-stone-800 tracking-tight">ToolShare</span>
            </Link>

            {/* Desktop Nav */}
            <nav className="hidden md:flex items-center gap-1">
              {navItems.map((item) => (
                <Link
                  key={item.page}
                  to={createPageUrl(item.page)}
                  className={`
                    flex items-center gap-2 px-4 py-2 rounded-lg transition-all duration-200
                    ${isActive(item.page) 
                      ? 'bg-[#6B8E7B]/10 text-[#6B8E7B]' 
                      : 'text-stone-600 hover:bg-stone-50 hover:text-stone-800'
                    }
                  `}
                >
                  <item.icon className="w-4 h-4" />
                  <span className="text-sm font-medium">{item.name}</span>
                </Link>
              ))}
            </nav>

            {/* User Menu */}
            <div className="flex items-center gap-3">
              {user ? (
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <button className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-stone-50 transition-colors">
                      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#6B8E7B] to-[#5a7a69] flex items-center justify-center text-white text-sm font-medium">
                        {user.full_name?.[0]?.toUpperCase() || user.email?.[0]?.toUpperCase()}
                      </div>
                      <span className="hidden sm:block text-sm font-medium text-stone-700">
                        {user.full_name || 'Account'}
                      </span>
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" className="w-56">
                    <div className="px-3 py-2">
                      <p className="font-medium text-stone-800">{user.full_name}</p>
                      <p className="text-sm text-stone-500 truncate">{user.email}</p>
                    </div>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem asChild>
                      <Link to={createPageUrl('MyTools')} className="cursor-pointer">
                        <Wrench className="w-4 h-4 mr-2" />
                        My Tools
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem asChild>
                      <Link to={createPageUrl('Requests')} className="cursor-pointer">
                        <Inbox className="w-4 h-4 mr-2" />
                        Requests
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem 
                      onClick={() => base44.auth.logout()}
                      className="text-red-600 cursor-pointer"
                    >
                      <LogOut className="w-4 h-4 mr-2" />
                      Log out
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              ) : (
                <Button 
                  onClick={() => base44.auth.redirectToLogin()}
                  className="bg-[#6B8E7B] hover:bg-[#5a7a69] text-white"
                >
                  <LogIn className="w-4 h-4 mr-2" />
                  Sign In
                </Button>
              )}

              {/* Mobile Menu Button */}
              <button
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                className="md:hidden p-2 rounded-lg hover:bg-stone-50"
              >
                {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
              </button>
            </div>
          </div>
        </div>

        {/* Mobile Nav */}
        <AnimatePresence>
          {mobileMenuOpen && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="md:hidden border-t border-stone-100 bg-white"
            >
              <nav className="p-4 space-y-1">
                {navItems.map((item) => (
                  <Link
                    key={item.page}
                    to={createPageUrl(item.page)}
                    onClick={() => setMobileMenuOpen(false)}
                    className={`
                      flex items-center gap-3 px-4 py-3 rounded-xl transition-all
                      ${isActive(item.page) 
                        ? 'bg-[#6B8E7B]/10 text-[#6B8E7B]' 
                        : 'text-stone-600 hover:bg-stone-50'
                      }
                    `}
                  >
                    <item.icon className="w-5 h-5" />
                    <span className="font-medium">{item.name}</span>
                  </Link>
                ))}
              </nav>
            </motion.div>
          )}
        </AnimatePresence>
      </header>

      {/* Main Content */}
      <main>
        {children}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-stone-100 mt-auto">
        <div className="max-w-7xl mx-auto px-4 py-8">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#6B8E7B] to-[#5a7a69] flex items-center justify-center">
                <Leaf className="w-4 h-4 text-white" />
              </div>
              <span className="font-bold text-stone-800">ToolShare</span>
            </div>
            <p className="text-sm text-stone-500">
              Building sustainable communities through sharing
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}