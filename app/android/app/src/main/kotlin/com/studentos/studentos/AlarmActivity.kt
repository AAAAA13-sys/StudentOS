package com.studentos.studentos

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.lang.ref.WeakReference
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.sqrt
import kotlin.random.Random

/**
 * The screen of a ringing alarm. It shows over the lock screen, ignores the
 * Back and volume keys, and only stops the alarm once the challenge is done.
 * Built in plain Android views so it works without starting Flutter.
 */
class AlarmActivity : Activity(), SensorEventListener {
    private val main = Handler(Looper.getMainLooper())
    private lateinit var root: LinearLayout
    private var sensors: SensorManager? = null
    private var shakesLeft = 0
    private var lastShake = 0L
    private var problemsLeft = 0
    private var answer = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockScreen()
        instance = WeakReference(this)
        root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(72), dp(24), dp(32))
        }
        val scroll = ScrollView(this).apply {
            setBackgroundColor(BG)
            isFillViewport = true
            addView(root)
        }
        setContentView(scroll)
        blockBack()
        render()
    }

    /**
     * Android 13+ sends Back (including the edge swipe) through
     * OnBackInvokedDispatcher, not key events, so it is swallowed here.
     */
    private fun blockBack() {
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                android.window.OnBackInvokedDispatcher.PRIORITY_OVERLAY,
            ) { /* ignored on purpose: the alarm must be solved */ }
        }
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    /** Draws the screen for whatever is ringing now. */
    private fun render() {
        stopShakeSensor()
        root.removeAllViews()
        val spec = AlarmService.current
        if (spec == null) {
            finish()
            return
        }
        root.addView(
            ImageView(this).apply {
                setImageResource(
                    if (AlarmService.currentIsCheck) R.drawable.ponpon_smug else R.drawable.ponpon_yelling,
                )
                contentDescription = "Ponpon the cat"
            },
            LinearLayout.LayoutParams(dp(120), dp(120)),
        )
        root.addView(text(SimpleDateFormat(
            if (android.text.format.DateFormat.is24HourFormat(this)) "HH:mm" else "h:mm a",
            Locale.getDefault(),
        ).format(Date()), 56f, bold = true))
        root.addView(text(spec.label.ifBlank { "Wake up" }, 22f, color = LILAC))
        root.addView(space(28))

        if (AlarmService.currentIsCheck) {
            root.addView(text("Still awake?", 26f, bold = true))
            root.addView(text("Answer within a minute or the alarm rings again.", 16f, color = LILAC))
            root.addView(space(24))
            root.addView(button("I'm up", primary = true) { AlarmService.send(this, AlarmService.ACTION_AWAKE) })
            return
        }

        when (spec.challenge) {
            "math" -> startMath(spec)
            "type" -> startTyping(spec)
            "shake" -> startShake(spec)
            else -> root.addView(button("Turn off", primary = true) { done() })
        }

        val left = AlarmService.snoozesLeft(this)
        if (left > 0) {
            root.addView(space(16))
            root.addView(
                button("Snooze ${spec.snoozeMinutes} min ($left left)", primary = false) {
                    AlarmService.send(this, AlarmService.ACTION_SNOOZE)
                },
            )
        }
    }

    private fun done() = AlarmService.send(this, AlarmService.ACTION_DISMISS)

    // Maths.

    private fun startMath(spec: AlarmSpec) {
        problemsLeft = spec.challengeCount
        val question = text("", 34f, bold = true)
        val progress = text("", 15f, color = LILAC)
        val input = EditText(this).apply {
            inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_SIGNED
            textSize = 28f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setHintTextColor(MUTED)
            hint = "Answer"
            background = box(SURFACE)
            setPadding(dp(16), dp(14), dp(16), dp(14))
            imeOptions = EditorInfo.IME_ACTION_DONE
        }
        val feedback = text("", 15f, color = WARN)
        fun next() {
            val (q, a) = problem(spec.difficulty)
            answer = a
            question.text = "$q = ?"
            progress.text = "$problemsLeft to go"
            input.setText("")
        }
        fun check() {
            val typed = input.text.toString().trim()
            // Close the keyboard after each answer so Snooze stays in view.
            (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager)
                .hideSoftInputFromWindow(input.windowToken, 0)
            // An empty field is not an answer (also stops a second submit
            // right after a correct one from counting as wrong).
            if (typed.isEmpty()) return
            val given = typed.toLongOrNull()
            if (given == answer) {
                problemsLeft--
                feedback.text = ""
                if (problemsLeft <= 0) done() else next()
            } else {
                // A wrong answer costs a new problem, not a free retry.
                feedback.text = "Wrong. Try this one."
                next()
            }
        }
        // The keyboard's Done key arrives with no event; a hardware Enter
        // arrives twice (down and up), so the key-down is ignored.
        input.setOnEditorActionListener { _, _, event ->
            if (event?.action != KeyEvent.ACTION_DOWN) check()
            true
        }
        root.addView(progress)
        root.addView(question)
        root.addView(space(16))
        root.addView(input, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        root.addView(feedback)
        root.addView(space(12))
        root.addView(button("Check", primary = true) { check() })
        next()
    }

    private fun problem(difficulty: String): Pair<String, Long> {
        val r = Random(System.nanoTime())
        return when (difficulty) {
            "easy" -> {
                val a = r.nextInt(12, 99); val b = r.nextInt(12, 99)
                "$a + $b" to (a + b).toLong()
            }
            "hard" -> {
                val a = r.nextInt(12, 30); val b = r.nextInt(12, 30)
                val c = r.nextInt(4, 13); val d = r.nextInt(11, 20)
                "$a × $b + $c × $d" to (a * b + c * d).toLong()
            }
            else -> {
                val a = r.nextInt(3, 10); val b = r.nextInt(11, 20); val c = r.nextInt(10, 99)
                "$a × $b + $c" to (a * b + c).toLong()
            }
        }
    }

    // Typing.

    private fun startTyping(spec: AlarmSpec) {
        val phrase = spec.phrase.trim()
        root.addView(text("Type this exactly", 15f, color = LILAC))
        root.addView(text("“$phrase”", 22f, bold = true))
        root.addView(space(16))
        val input = EditText(this).apply {
            // No suggestions or autocorrect: it has to be typed out.
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS or
                InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
            textSize = 18f
            setTextColor(Color.WHITE)
            setHintTextColor(MUTED)
            hint = "Type here"
            background = box(SURFACE)
            setPadding(dp(16), dp(14), dp(16), dp(14))
        }
        val feedback = text("", 15f, color = WARN)
        root.addView(input, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        root.addView(feedback)
        root.addView(space(12))
        root.addView(button("Turn off", primary = true) {
            if (input.text.toString().trim() == phrase) done()
            else feedback.text = "Not quite. Every letter counts."
        })
    }

    // Shaking.

    private fun startShake(spec: AlarmSpec) {
        shakesLeft = spec.challengeCount
        root.addView(text("Shake the phone", 26f, bold = true))
        shakeLabel = text("$shakesLeft shakes left", 20f, color = LILAC)
        root.addView(shakeLabel)
        sensors = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val accel = sensors?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (accel == null) {
            // No sensor: fall back to the plain button rather than trap the user.
            root.addView(space(16))
            root.addView(button("Turn off", primary = true) { done() })
        } else {
            sensors?.registerListener(this, accel, SensorManager.SENSOR_DELAY_GAME)
        }
    }

    private var shakeLabel: TextView? = null

    override fun onSensorChanged(event: SensorEvent) {
        val (x, y, z) = Triple(event.values[0], event.values[1], event.values[2])
        val g = sqrt(x * x + y * y + z * z) / SensorManager.GRAVITY_EARTH
        val now = System.currentTimeMillis()
        if (g > 2.3f && now - lastShake > 350) {
            lastShake = now
            shakesLeft--
            shakeLabel?.text = "$shakesLeft shakes left"
            if (shakesLeft <= 0) {
                stopShakeSensor()
                done()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun stopShakeSensor() {
        sensors?.unregisterListener(this)
        sensors = null
    }

    // Keys: Back and volume do nothing while it rings.

    @Deprecated("Back must not leave the alarm")
    override fun onBackPressed() { /* ignored on purpose */ }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        return when (event.keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP, KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_VOLUME_MUTE, KeyEvent.KEYCODE_BACK -> true
            else -> super.dispatchKeyEvent(event)
        }
    }

    override fun onDestroy() {
        stopShakeSensor()
        main.removeCallbacksAndMessages(null)
        if (instance?.get() === this) instance = null
        super.onDestroy()
    }

    // Small view helpers.

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    private fun space(h: Int) = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(1, dp(h))
    }

    private fun box(color: Int) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(14).toFloat()
        setStroke(dp(1), HAIRLINE)
    }

    private fun text(s: String, size: Float, bold: Boolean = false, color: Int = Color.WHITE) =
        TextView(this).apply {
            text = s
            textSize = size
            setTextColor(color)
            gravity = Gravity.CENTER
            if (bold) typeface = Typeface.DEFAULT_BOLD
            setPadding(0, dp(4), 0, dp(4))
        }

    private fun button(label: String, primary: Boolean, onTap: () -> Unit) = Button(this).apply {
        text = label
        textSize = 18f
        isAllCaps = false
        setTextColor(if (primary) BG else Color.WHITE)
        background = box(if (primary) LILAC else SURFACE)
        minHeight = dp(56)
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT,
        )
        setOnClickListener { onTap() }
    }

    companion object {
        // Midnight Lavender, from DESIGN_SYSTEM.md.
        private val BG = Color.parseColor("#0B0720")
        private val SURFACE = Color.parseColor("#25134D")
        private val HAIRLINE = Color.parseColor("#491F8E")
        private val LILAC = Color.parseColor("#D1B8FF")
        private val MUTED = Color.parseColor("#9D71E8")
        private val WARN = Color.parseColor("#FDA4AF")

        private var instance: WeakReference<AlarmActivity>? = null

        /** Redraws the open alarm screen (e.g. a check turned into a ring). */
        fun refresh() {
            instance?.get()?.let { a -> a.runOnUiThread { a.render() } }
        }

        fun close() {
            instance?.get()?.let { a -> a.runOnUiThread { a.finish() } }
        }
    }
}
