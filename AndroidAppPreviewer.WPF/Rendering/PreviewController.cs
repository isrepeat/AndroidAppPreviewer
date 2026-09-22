using System.Windows.Threading;

namespace AndroidAppPreviewer {
    internal sealed class PreviewController : IDisposable {
        private readonly PluginSessionController pluginSessionController;
        private readonly DispatcherTimer renderTimer;
        private readonly DispatcherTimer animationTimer;
#if DEBUG
        private long frameTimingWindowStarted = System.Diagnostics.Stopwatch.GetTimestamp();
        private int timedFrameCount;
        private TimeSpan totalUpdateTime;
        private TimeSpan totalNativeRenderTime;
        private TimeSpan totalBitmapCreationTime;
        private TimeSpan totalImageAssignmentTime;
        private TimeSpan totalFrameTime;
#endif
        private bool isDisposed;

        public event Action? RenderRequested;
        public event Action<NativePreviewSession>? FrameUpdated;
        public event Action<Exception>? Failed;

        public PreviewController(Dispatcher dispatcher, PluginSessionController pluginSessionController) {
            this.pluginSessionController = pluginSessionController;
            this.renderTimer = new DispatcherTimer(DispatcherPriority.Normal, dispatcher) {
                Interval = TimeSpan.FromMilliseconds(250),
            };
            this.renderTimer.Tick += this.RenderTimerTick;
            this.animationTimer = new DispatcherTimer(DispatcherPriority.Normal, dispatcher) {
                Interval = TimeSpan.FromMilliseconds(16),
            };
            this.animationTimer.Tick += this.AnimationTimerTick;
        }

        public NativePreviewSession? Session => this.pluginSessionController.Session;

        public (NativePreviewSession Session, bool IsNew) EnsureSession(
            int width,
            int height) {
            var session = this.Session;
            if (session is not null && session.Width == width && session.Height == height) {
                return (session, false);
            }
            this.StopAnimation();
            return (this.pluginSessionController.CreateSession(width, height), true);
        }

        public void ScheduleRender() {
            if (this.isDisposed) {
                return;
            }
            this.renderTimer.Stop();
            this.renderTimer.Start();
        }

        public void StartAnimation() {
            if (!this.isDisposed) {
                this.animationTimer.Start();
            }
        }

        public void StopAnimation() {
            this.animationTimer.Stop();
        }

        public void Reset() {
            this.StopAnimation();
            this.pluginSessionController.Reset();
        }

        public void Dispose() {
            if (this.isDisposed) {
                return;
            }
            this.isDisposed = true;
            this.renderTimer.Stop();
            this.animationTimer.Stop();
            this.pluginSessionController.Dispose();
        }

        private void RenderTimerTick(object? sender, EventArgs eventArgs) {
            this.renderTimer.Stop();
            this.RenderRequested?.Invoke();
        }

        private void AnimationTimerTick(object? sender, EventArgs eventArgs) {
            try {
                var session = this.Session;
                if (session is null) {
                    return;
                }
#if DEBUG
                var frameStarted = System.Diagnostics.Stopwatch.GetTimestamp();
#endif
                session.UpdateAndRender();
                this.FrameUpdated?.Invoke(session);
#if DEBUG
                this.RecordFrameTiming(
                    session.LastFrameTiming,
                    System.Diagnostics.Stopwatch.GetElapsedTime(frameStarted));
#endif
            } catch (Exception exception) {
                this.Failed?.Invoke(exception);
            }
        }

#if DEBUG
        private void RecordFrameTiming(PreviewFrameTiming timing, TimeSpan frameTime) {
            this.timedFrameCount++;
            this.totalUpdateTime += timing.Update;
            this.totalNativeRenderTime += timing.NativeRender;
            this.totalBitmapCreationTime += timing.BitmapCreation;
            this.totalImageAssignmentTime += timing.ImageAssignment;
            this.totalFrameTime += frameTime;

            var elapsed = System.Diagnostics.Stopwatch.GetElapsedTime(this.frameTimingWindowStarted);
            if (elapsed < TimeSpan.FromSeconds(1)) {
                return;
            }

            var count = this.timedFrameCount;
            this.pluginSessionController.LogInfo(
                $"Preview frame timing: fps={count / elapsed.TotalSeconds:F1}; "
                + $"update={this.totalUpdateTime.TotalMilliseconds / count:F2} ms; "
                + $"nativeRender={this.totalNativeRenderTime.TotalMilliseconds / count:F2} ms; "
                + $"bitmap={this.totalBitmapCreationTime.TotalMilliseconds / count:F2} ms; "
                + $"image={this.totalImageAssignmentTime.TotalMilliseconds / count:F2} ms; "
                + $"frame={this.totalFrameTime.TotalMilliseconds / count:F2} ms; "
                + $"window={elapsed.TotalMilliseconds:F0} ms");

            this.frameTimingWindowStarted = System.Diagnostics.Stopwatch.GetTimestamp();
            this.timedFrameCount = 0;
            this.totalUpdateTime = TimeSpan.Zero;
            this.totalNativeRenderTime = TimeSpan.Zero;
            this.totalBitmapCreationTime = TimeSpan.Zero;
            this.totalImageAssignmentTime = TimeSpan.Zero;
            this.totalFrameTime = TimeSpan.Zero;
        }
#endif
    }
}