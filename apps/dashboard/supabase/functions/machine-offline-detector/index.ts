import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    console.log('Starting machine offline detection...')

    // Find machines that should be marked offline
    // Criteria: last_ping > 2 minutes ago AND connection_status = 'online'
    const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000).toISOString()
    
    const { data: offlineMachines, error: fetchError } = await supabase
      .from('machines')
      .select('id, name, machine_code, last_ping, connection_status')
      .lt('last_ping', twoMinutesAgo)
      .eq('connection_status', 'online')

    if (fetchError) {
      console.error('Error fetching machines:', fetchError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to fetch machines',
          details: fetchError.message
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    console.log(`Found ${offlineMachines?.length || 0} machines that should be marked offline`)

    if (!offlineMachines || offlineMachines.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No machines need to be marked offline',
          machines_checked: 0,
          machines_marked_offline: 0,
          timestamp: new Date().toISOString()
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Update machines to offline status
    const machineIds = offlineMachines.map(machine => machine.id)
    
    const { data: updatedMachines, error: updateError } = await supabase
      .from('machines')
      .update({
        connection_status: 'offline',
        is_online: false,
        last_offline: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .in('id', machineIds)
      .select('id, name, machine_code, connection_status, last_ping, last_offline')

    if (updateError) {
      console.error('Error updating machines:', updateError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to update machines',
          details: updateError.message
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Log detailed information about offline machines
    console.log('Machines marked offline:')
    offlineMachines.forEach(machine => {
      const lastPingTime = machine.last_ping ? new Date(machine.last_ping).toISOString() : 'Never'
      const timeSinceLastPing = machine.last_ping ? 
        Math.round((Date.now() - new Date(machine.last_ping).getTime()) / 1000 / 60) : 
        'Unknown'
      
      console.log(`- ${machine.name} (${machine.machine_code}): Last ping ${lastPingTime}, ${timeSinceLastPing} minutes ago`)
    })

    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully marked ${updatedMachines?.length || 0} machines as offline`,
        machines_checked: offlineMachines.length,
        machines_marked_offline: updatedMachines?.length || 0,
        offline_machines: updatedMachines,
        timestamp: new Date().toISOString(),
        detection_criteria: {
          time_threshold_minutes: 2,
          cutoff_time: twoMinutesAgo
        }
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Machine offline detector error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Internal server error',
        details: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}) 