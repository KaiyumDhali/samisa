<?php

namespace App\Http\Controllers\Apps;

use App\DataTables\UsersDataTable;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;




class UserManagementController extends Controller
{


    public function updatePassword(Request $request, $id)
    {


        // $request->validate([
        //     'current_password' => 'required',
        //     'new_password' => 'required|min:8|confirmed', // expects new_password_confirmation field too
        // ]);

        $user = User::find($id);

        // $user = User::where('id', $id)->first();
        // $user = Auth::user();

        // if (!Hash::check($request->current_password, $user->password)) {
        //     return back()->withErrors(['current_password' => 'Current password is incorrect']);
        // }

        $user->update([
            'password' => Hash::make($request->new_password),
        ]);

        return back()->with('success', 'Password changed successfully!');
    }

    /**
     * Display a listing of the resource.
     */
    public function index(UsersDataTable $dataTable)
    {
        return $dataTable->render('pages.apps.user-management.users.list');
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(User $user)
    {
        return view('pages.apps.user-management.users.show', compact('user'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(User $user)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, User $user)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(User $user)
    {
        //
    }
}
