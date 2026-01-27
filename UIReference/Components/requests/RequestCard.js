import React from 'react';
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { format } from 'date-fns';
import { Calendar, CheckCircle, XCircle, Clock, RotateCcw } from 'lucide-react';
import { motion } from 'framer-motion';

const statusConfig = {
  pending: {
    color: "bg-amber-50 text-amber-700 border-amber-200",
    icon: Clock,
    label: "Pending"
  },
  approved: {
    color: "bg-emerald-50 text-emerald-700 border-emerald-200",
    icon: CheckCircle,
    label: "Approved"
  },
  declined: {
    color: "bg-red-50 text-red-700 border-red-200",
    icon: XCircle,
    label: "Declined"
  },
  returned: {
    color: "bg-stone-50 text-stone-600 border-stone-200",
    icon: RotateCcw,
    label: "Returned"
  }
};

export default function RequestCard({ 
  request, 
  type = 'incoming', 
  onApprove, 
  onDecline, 
  onMarkReturned,
  index = 0 
}) {
  const status = statusConfig[request.status] || statusConfig.pending;
  const StatusIcon = status.icon;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05 }}
    >
      <Card className="p-5 bg-white border-0 shadow-sm hover:shadow-md transition-shadow">
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <h4 className="font-semibold text-stone-800 truncate">{request.tool_name}</h4>
              <Badge variant="outline" className={`${status.color} border shrink-0`}>
                <StatusIcon className="w-3 h-3 mr-1" />
                {status.label}
              </Badge>
            </div>
            
            <p className="text-sm text-stone-500 mb-3">
              {type === 'incoming' 
                ? `From: ${request.borrower_name || request.borrower_email}`
                : `Owner: ${request.owner_email}`
              }
            </p>

            {request.message && (
              <p className="text-sm text-stone-600 bg-stone-50 rounded-lg p-3 mb-3 italic">
                "{request.message}"
              </p>
            )}

            <div className="flex items-center gap-4 text-xs text-stone-400">
              {request.start_date && (
                <span className="flex items-center gap-1">
                  <Calendar className="w-3.5 h-3.5" />
                  {format(new Date(request.start_date), 'MMM d')} 
                  {request.end_date && ` - ${format(new Date(request.end_date), 'MMM d')}`}
                </span>
              )}
            </div>
          </div>

          {type === 'incoming' && request.status === 'pending' && (
            <div className="flex gap-2 shrink-0">
              <Button
                size="sm"
                variant="outline"
                onClick={() => onDecline(request)}
                className="text-red-600 border-red-200 hover:bg-red-50"
              >
                <XCircle className="w-4 h-4" />
              </Button>
              <Button
                size="sm"
                onClick={() => onApprove(request)}
                className="bg-[#6B8E7B] hover:bg-[#5a7a69] text-white"
              >
                <CheckCircle className="w-4 h-4 mr-1" />
                Approve
              </Button>
            </div>
          )}

          {type === 'incoming' && request.status === 'approved' && (
            <Button
              size="sm"
              variant="outline"
              onClick={() => onMarkReturned(request)}
              className="shrink-0"
            >
              <RotateCcw className="w-4 h-4 mr-1" />
              Mark Returned
            </Button>
          )}
        </div>
      </Card>
    </motion.div>
  );
}