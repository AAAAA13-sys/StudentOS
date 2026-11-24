package com.studentos.studentos

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import java.util.Locale

/**
 * Android Quick Settings tile for the Focus timer. Reads [FocusStore] on-device
 * only: shows idle ("Focus" / "Start session") or the active phase with live
 * remaining `MM:SS left` (or "Paused"), and opens/starts Focus in StudentOS.
 */
@RequiresApi(Build.VERSION_CODES.N)
class FocusTileService : TileService() {
    override fun onTileAdded() {
        super.onTileAdded()
        refreshTile()
    }

    override fun onStartListening() {
        super.onStartListening()
        refreshTile()
    }

    override fun onClick() {
        super.onClick()
        val now = System.currentTimeMillis()
        val session = FocusStore.session(this)
        val phase = session?.let { FocusStore.phaseAt(it, now) }
        val route = if (phase != null) MainActivity.ROUTE_TIMER else MainActivity.ROUTE_START_FOCUS
        val intent = Intent(this, MainActivity::class.java)
            .putExtra(MainActivity.EXTRA_ROUTE, route)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pi = PendingIntent.getActivity(
                this,
                TILE_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pi)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun refreshTile() {
        val tile = qsTile ?: return
        val now = System.currentTimeMillis()
        val session = FocusStore.session(this)
        val phase = session?.let { FocusStore.phaseAt(it, now) }

        if (phase == null) {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "Focus"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = "Start session"
            }
        } else {
            tile.state = Tile.STATE_ACTIVE
            val title = if (phase.kind == "focus") "Focus" else "Break"
            val paused = !session.isNull("pausedAt")
            val sub = if (paused) {
                "Paused"
            } else {
                val remainingSec = ((phase.end - now).coerceAtLeast(0L) / 1000L).toInt()
                val mm = remainingSec / 60
                val ss = remainingSec % 60
                String.format(Locale.US, "%02d:%02d left", mm, ss)
            }
            tile.label = title
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = sub
            } else {
                tile.label = "$title · $sub"
            }
        }
        tile.updateTile()
    }

    companion object {
        private const val TILE_REQUEST_CODE = 4610

        fun requestListening(ctx: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    requestListeningState(ctx, ComponentName(ctx, FocusTileService::class.java))
                } catch (_: Exception) {
                }
            }
        }
    }
}
