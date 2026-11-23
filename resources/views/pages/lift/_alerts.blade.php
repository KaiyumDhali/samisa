@if ($errors->any())
    <div class="alert alert-danger py-3">
        @foreach ($errors->all() as $error)
            <div>{{ $error }}</div>
        @endforeach
    </div>
@endif
