package com.rtsda.appr.ui.components

import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.webkit.WebView

class RefreshableWebView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : WebView(context, attrs, defStyleAttr) {
    
    private var startY = 0f
    private var enableRefresh = true
    
    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                startY = event.y
                enableRefresh = scrollY == 0
            }
            MotionEvent.ACTION_MOVE -> {
                if (enableRefresh && scrollY == 0 && event.y > startY) {
                    // If we're at the top and pulling down, let the parent handle it
                    parent?.requestDisallowInterceptTouchEvent(false)
                    return false
                }
            }
        }
        parent?.requestDisallowInterceptTouchEvent(true)
        return super.onTouchEvent(event)
    }
}
