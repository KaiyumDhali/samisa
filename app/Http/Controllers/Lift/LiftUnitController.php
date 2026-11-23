<?php

namespace App\Http\Controllers\Lift;

use App\Models\Lift\LiftUnit;
use Illuminate\Http\Request;

class LiftUnitController extends LiftBaseController
{
    function __construct()
    {
        $this->guardPermissions(['index']);
    }

    public function index(Request $request)
    {
        $units = LiftUnit::with('customer')
            ->when(
                $request->filled('customer_id'),
                fn($q) => $q->where('customer_id', $request->customer_id)
            )
            ->orderBy('customer_id')
            ->orderBy('id')
            ->get();

        return view('pages.lift.units.index', [
            'units' => $units,
            'customers' => $this->customers(),
            'customerId' => $request->customer_id
        ]);
    }

    public function create()
    {
        return view('pages.lift.units.form', [
            'unit' => new LiftUnit(['status' => 1]),
            'customers' => $this->customers()
        ]);
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);

        LiftUnit::create($data + [
            'done_by' => $this->user()
        ]);

        return redirect()
            ->route('lift.units.index')
            ->with([
                'message' => 'Lift added successfully.',
                'alert-type' => 'success'
            ]);
    }

    public function edit(LiftUnit $unit)
    {
        return view('pages.lift.units.form', [
            'unit' => $unit,
            'customers' => $this->customers()
        ]);
    }

    public function update(Request $request, LiftUnit $unit)
    {
        $unit->update($this->validated($request));

        return redirect()
            ->route('lift.units.index')
            ->with([
                'message' => 'Lift updated successfully.',
                'alert-type' => 'success'
            ]);
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'customer_id' => 'required|integer|exists:finance_accounts,id',
            'lift_code' => 'nullable|string|max:50',
            'site_name' => 'required|string|max:150',
            'site_address' => 'nullable|string',
            'brand' => 'nullable|string|max:100',
            'model' => 'nullable|string|max:100',
            'capacity_persons' => 'nullable|integer|min:0',
            'floors' => 'nullable|integer|min:0',
            'installation_date' => 'nullable|date',
            'status' => 'required|in:0,1',
            'remarks' => 'nullable|string',
        ]);
    }
}
