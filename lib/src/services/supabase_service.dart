// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/iptv_models.dart';
import '../models/m3u_playlist.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();
  final Logger _logger = Logger();

  SupabaseClient? get _maybeClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isLoggedIn => _maybeClient?.auth.currentUser != null;

  Future<AuthResponse> signIn(String email, String password) {
    final client = _maybeClient;
    if (client == null) {
      throw StateError('Supabase not initialized');
    }
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) {
    final client = _maybeClient;
    if (client == null) {
      throw StateError('Supabase not initialized');
    }
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    final client = _maybeClient;
    if (client != null) {
      await client.auth.signOut();
    }
  }

  Future<List<IptvItem>> fetchItems() async {
    final client = _maybeClient;
    if (client == null) return [];
    final data = await client
        .from('items')
        .select()
        .order('parentId')
        .order('position') as List<dynamic>;
    return data
        .map((e) => IptvItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveItems(List<IptvItem> items) async {
    try {
      final client = _maybeClient;
      if (client != null) {
        await client.from('items').upsert(items.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      _logger.e('Save items failed', error: e);
    }
  }

  Future<List<M3uPlaylist>> fetchPlaylists() async {
    final client = _maybeClient;
    if (client == null) return [];
    final data = await client.from('playlists').select() as List<dynamic>;
    return data
        .map((e) => M3uPlaylist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePlaylists(List<M3uPlaylist> playlists) async {
    try {
      final client = _maybeClient;
      if (client != null) {
        await client
            .from('playlists')
            .upsert(playlists.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      _logger.e('Save playlists failed', error: e);
    }
  }

  Future<String?> uploadLogo(File file) async {
    try {
      final client = _maybeClient;
      if (client == null) return null;
      final name = p.basename(file.path);
      await client.storage.from('logos').upload('public/$name', file);
      return client.storage.from('logos').getPublicUrl('public/$name');
    } catch (e) {
      _logger.e('Upload logo failed', error: e);
      return null;
    }
  }

  Future<List<String>> fetchLogos() async {
    try {
      final client = _maybeClient;
      if (client == null) return [];
      final files = await client.storage
          .from('logos')
          .list(path: 'public', searchOptions: const SearchOptions(limit: 1000));
      final urls = files
          .map((f) => client.storage.from('logos').getPublicUrl('public/${f.name}'))
          .toList()
        ..sort();
      return urls;
    } catch (e) {
      _logger.e('Fetch logos failed', error: e);
      return [];
    }
  }

  Future<void> deleteLogo(String url) async {
    try {
      final client = _maybeClient;
      if (client == null) return;
      final name = p.basename(url);
      await client.storage.from('logos').remove(['public/$name']);
    } catch (e) {
      _logger.e('Delete logo failed', error: e);
    }
  }
}
