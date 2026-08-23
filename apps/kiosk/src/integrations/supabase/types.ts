export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instanciate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "12.2.12 (cd3cf9e)"
  }
  public: {
    Tables: {
      machine_products: {
        Row: {
          created_at: string
          current_stock: number
          id: string
          machine_id: string
          max_stock_recorded: number | null
          par_level: number
          price_override: number | null
          product_id: string
          slot_position: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          current_stock?: number
          id?: string
          machine_id: string
          max_stock_recorded?: number | null
          par_level?: number
          price_override?: number | null
          product_id: string
          slot_position?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          current_stock?: number
          id?: string
          machine_id?: string
          max_stock_recorded?: number | null
          par_level?: number
          price_override?: number | null
          product_id?: string
          slot_position?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "machine_products_machine_id_fkey"
            columns: ["machine_id"]
            isOneToOne: false
            referencedRelation: "machines"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "machine_products_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      machines: {
        Row: {
          alerts_count: number | null
          battery_level: number | null
          connection_status: string | null
          created_at: string
          id: string
          is_online: boolean | null
          is_paired: boolean | null
          last_offline: string | null
          last_ping: string | null
          last_sync: string | null
          location: string | null
          machine_code: string
          machine_token: string | null
          name: string
          status: string
          status_data: Json | null
          total_stock_level: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          alerts_count?: number | null
          battery_level?: number | null
          connection_status?: string | null
          created_at?: string
          id?: string
          is_online?: boolean | null
          is_paired?: boolean | null
          last_offline?: string | null
          last_ping?: string | null
          last_sync?: string | null
          location?: string | null
          machine_code: string
          machine_token?: string | null
          name: string
          status?: string
          status_data?: Json | null
          total_stock_level?: number | null
          updated_at?: string
          user_id: string
        }
        Update: {
          alerts_count?: number | null
          battery_level?: number | null
          connection_status?: string | null
          created_at?: string
          id?: string
          is_online?: boolean | null
          is_paired?: boolean | null
          last_offline?: string | null
          last_ping?: string | null
          last_sync?: string | null
          location?: string | null
          machine_code?: string
          machine_token?: string | null
          name?: string
          status?: string
          status_data?: Json | null
          total_stock_level?: number | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      pending_machine_links: {
        Row: {
          created_at: string
          expires_at: string
          id: string
          machine_id: string | null
          pairing_code: string
          status: string
          updated_at: string
          used_at: string | null
        }
        Insert: {
          created_at?: string
          expires_at: string
          id?: string
          machine_id?: string | null
          pairing_code: string
          status?: string
          updated_at?: string
          used_at?: string | null
        }
        Update: {
          created_at?: string
          expires_at?: string
          id?: string
          machine_id?: string | null
          pairing_code?: string
          status?: string
          updated_at?: string
          used_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "pending_machine_links_machine_id_fkey"
            columns: ["machine_id"]
            isOneToOne: false
            referencedRelation: "machines"
            referencedColumns: ["id"]
          },
        ]
      }
      product_images: {
        Row: {
          created_at: string
          file_hash: string | null
          file_name: string | null
          file_size: number | null
          height: number | null
          id: string
          image_url: string
          is_primary: boolean
          metadata: Json | null
          mime_type: string | null
          product_id: string
          uploader_id: string | null
          width: number | null
        }
        Insert: {
          created_at?: string
          file_hash?: string | null
          file_name?: string | null
          file_size?: number | null
          height?: number | null
          id?: string
          image_url: string
          is_primary?: boolean
          metadata?: Json | null
          mime_type?: string | null
          product_id: string
          uploader_id?: string | null
          width?: number | null
        }
        Update: {
          created_at?: string
          file_hash?: string | null
          file_name?: string | null
          file_size?: number | null
          height?: number | null
          id?: string
          image_url?: string
          is_primary?: boolean
          metadata?: Json | null
          mime_type?: string | null
          product_id?: string
          uploader_id?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "product_images_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          base_price: number
          category: string
          created_at: string
          description: string | null
          id: string
          name: string
          product_code: string
          updated_at: string
          user_id: string
        }
        Insert: {
          base_price: number
          category: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          product_code: string
          updated_at?: string
          user_id: string
        }
        Update: {
          base_price?: number
          category?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          product_code?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          avatar_url: string | null
          company_name: string | null
          created_at: string
          full_name: string | null
          id: string
          is_onboarded: boolean
          phone_number: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          avatar_url?: string | null
          company_name?: string | null
          created_at?: string
          full_name?: string | null
          id?: string
          is_onboarded?: boolean
          phone_number?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          avatar_url?: string | null
          company_name?: string | null
          created_at?: string
          full_name?: string | null
          id?: string
          is_onboarded?: boolean
          phone_number?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      stock_transactions: {
        Row: {
          created_at: string
          id: string
          machine_id: string
          new_stock: number
          notes: string | null
          performed_by: string
          previous_stock: number
          product_id: string
          quantity_change: number
          transaction_type: string
        }
        Insert: {
          created_at?: string
          id?: string
          machine_id: string
          new_stock: number
          notes?: string | null
          performed_by: string
          previous_stock: number
          product_id: string
          quantity_change: number
          transaction_type: string
        }
        Update: {
          created_at?: string
          id?: string
          machine_id?: string
          new_stock?: number
          notes?: string | null
          performed_by?: string
          previous_stock?: number
          product_id?: string
          quantity_change?: number
          transaction_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "stock_transactions_machine_id_fkey"
            columns: ["machine_id"]
            isOneToOne: false
            referencedRelation: "machines"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stock_transactions_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      user_2fa: {
        Row: {
          backup_codes: string[] | null
          created_at: string
          id: string
          is_enabled: boolean
          secret: string
          updated_at: string
          user_id: string
        }
        Insert: {
          backup_codes?: string[] | null
          created_at?: string
          id?: string
          is_enabled?: boolean
          secret: string
          updated_at?: string
          user_id: string
        }
        Update: {
          backup_codes?: string[] | null
          created_at?: string
          id?: string
          is_enabled?: boolean
          secret?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_preferences: {
        Row: {
          created_at: string
          default_landing_page: string
          default_machine_view: string
          id: string
          notifications_low_inventory: boolean
          notifications_machine_errors: boolean
          notifications_weekly_reports: boolean
          theme: string
          timezone: string
          unit_system: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          default_landing_page?: string
          default_machine_view?: string
          id?: string
          notifications_low_inventory?: boolean
          notifications_machine_errors?: boolean
          notifications_weekly_reports?: boolean
          theme?: string
          timezone?: string
          unit_system?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          default_landing_page?: string
          default_machine_view?: string
          id?: string
          notifications_low_inventory?: boolean
          notifications_machine_errors?: boolean
          notifications_weekly_reports?: boolean
          theme?: string
          timezone?: string
          unit_system?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      live_stream_offers: {
        Row: {
          id: string
          machine_id: string
          offer: Json
          created_at: string
          expires_at: string
          status: string
        }
        Insert: {
          id?: string
          machine_id: string
          offer: Json
          created_at?: string
          expires_at?: string
          status?: string
        }
        Update: {
          id?: string
          machine_id?: string
          offer?: Json
          created_at?: string
          expires_at?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "live_stream_offers_machine_id_fkey"
            columns: ["machine_id"]
            isOneToOne: false
            referencedRelation: "machines"
            referencedColumns: ["id"]
          }
        ]
      }
      live_stream_answers: {
        Row: {
          id: string
          offer_id: string
          answer: Json
          machine_id: string
          created_at: string
        }
        Insert: {
          id?: string
          offer_id: string
          answer: Json
          machine_id: string
          created_at?: string
        }
        Update: {
          id?: string
          offer_id?: string
          answer?: Json
          machine_id?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "live_stream_answers_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "live_stream_offers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_stream_answers_machine_id_fkey"
            columns: ["machine_id"]
            isOneToOne: false
            referencedRelation: "machines"
            referencedColumns: ["id"]
          }
        ]
      }
      live_stream_ice_candidates: {
        Row: {
          id: string
          offer_id: string
          candidate: Json
          machine_id: string
          created_at: string
        }
        Insert: {
          id?: string
          offer_id: string
          candidate: Json
          machine_id: string
          created_at?: string
        }
        Update: {
          id?: string
          offer_id?: string
          candidate?: Json
          machine_id?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "live_stream_ice_candidates_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "live_stream_offers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "live_stream_ice_candidates_machine_id_fkey"
            columns: ["machine_id"]
            isOneToOne: false
            referencedRelation: "machines"
            referencedColumns: ["id"]
          }
        ]
      }
      stream_frames: {
        Row: {
          id: string
          machine_id: string
          image_data: string
          timestamp: string
          frame_number: number
          created_at: string
        }
        Insert: {
          id?: string
          machine_id: string
          image_data: string
          timestamp?: string
          frame_number: number
          created_at?: string
        }
        Update: {
          id?: string
          machine_id?: string
          image_data?: string
          timestamp?: string
          frame_number?: number
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "stream_frames_machine_id_fkey"
            columns: ["machine_id"]
            isOneToOne: false
            referencedRelation: "machines"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      calculate_machine_stock_level: {
        Args: { machine_uuid: string }
        Returns: number
      }
      cleanup_expired_pending_links: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      complete_machine_pairing: {
        Args: {
          pairing_code_param: string
          machine_code_param: string
          machine_token_param: string
        }
        Returns: {
          success: boolean
          message: string
        }[]
      }
      create_pending_machine_link: {
        Args: Record<PropertyKey, never>
        Returns: {
          pairing_code: string
          link_id: string
        }[]
      }
      create_pending_machine_link_kiosk: {
        Args: Record<PropertyKey, never>
        Returns: {
          id: string
          pairing_code: string
          expires_at: string
        }[]
      }
      generate_pairing_code: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      get_machine_id_by_pairing_code: {
        Args: { code: string }
        Returns: {
          machine_id: string
          machine_token: string
        }[]
      }
      machine_checkin: {
        Args: { p_machine_id: string; p_status: Json }
        Returns: Json
      }
      mark_offline_machines: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      pair_machine_with_code: {
        Args: {
          p_pairing_code: string
          p_machine_name: string
          p_location: string
          p_machine_code: string
        }
        Returns: {
          machine_id: string
          machine_token: string
          success: boolean
          message: string
        }[]
      }
      pair_machine_with_code_v2: {
        Args: {
          p_pairing_code: string
          p_machine_name: string
          p_location: string
          p_machine_code: string
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
